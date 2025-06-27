# Instalação e Configuração do Whisper Transcriber com Docker no WSL2
# Autor: Baseado em Marcio Rosner (malvesro)
# Versão: 1.0.19 (Correção da verificação de existência do arquivo setup.sh)

# --- Variáveis Globais de Configuração ---
# O nome do script deve ser Instalador_Whisper.ps1
$scriptName = $MyInvocation.MyCommand.Name

# URL do seu repositório GitHub
$RepoUrl = "https://github.com/malvesro/transcribe.git"
# Nome do diretório que será clonado no WSL
$RepoDir = "transcribe"
# O nome PREDETERMINADO que o script tentará instalar ou usar para a distro Ubuntu
$DesiredUbuntuDistroName = "Ubuntu" 

# --- Funções Auxiliares ---
function Write-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "===========================================================" -ForegroundColor Cyan
    Write-Host "          $Text" -ForegroundColor White
    Write-Host "===========================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info {
    param([string]$Message)
    Write-Host ">>> $Message" -ForegroundColor White
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ ATENÇÃO: $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg {
    param([string]$Message)
    Write-Host "!!! ERRO: $Message" -ForegroundColor Red
}

function Pause-Script {
    param([string]$Prompt = "Pressione qualquer tecla para continuar...")
    Write-Host "`n-----------------------------------------------------------"
    Write-Host $Prompt -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------`n"
    [void]$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
}

# --- Funções Principais de Setup ---

function Check-ExecutionPolicy {
    Write-Info "Verificando a política de execução do PowerShell..."
    $policy = Get-ExecutionPolicy
    if ($policy -ne "RemoteSigned" -and $policy -ne "Unrestricted") {
        Write-Warning "A política de execução atual é '$policy'. Recomendado 'RemoteSigned' ou 'Unrestricted'."
        Write-Info "Tentando definir a política para 'RemoteSigned'..."
        try {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Write-Success "Política de execução definida para 'RemoteSigned'."
        }
        catch {
            Write-ErrorMsg "Não foi possível definir a política de execução. Por favor, execute manualmente: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
            return $false
        }
    } else {
        Write-Success "Política de execução adequada detectada: '$policy'."
    }
    return $true
}

function Check-AdminPrivileges {
    Write-Info "Verificando privilégios de administrador..."
    $isAdmin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-ErrorMsg "Este script precisa ser executado como Administrador. Por favor, feche e reabra o PowerShell como Administrador."
        return $false
    }
    Write-Success "Privilégios de administrador OK."
    return $true
}

function Install-WSL2 {
    Write-Info "Verificando e instalando/atualizando WSL2 e Ubuntu..."

    # Verifica o status dos recursos obrigatórios do Windows para WSL
    $wslFeatureEnabled = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -ErrorAction SilentlyContinue).State -eq "Enabled"
    $vmPlatformEnabled = (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -ErrorAction SilentlyContinue).State -eq "Enabled"

    $featuresToEnable = @()
    if (-not $wslFeatureEnabled) {
        $featuresToEnable += "Microsoft-Windows-Subsystem-Linux"
    }
    if (-not $vmPlatformEnabled) {
        $featuresToEnable += "VirtualMachinePlatform"
    }

    if ($featuresToEnable.Count -gt 0) {
        Write-Info "Habilitando recurso(s) do Windows necessários para WSL. Isso pode levar alguns minutos..."
        foreach ($feature in $featuresToEnable) {
            Write-Info "Habilitando recurso: $feature"
            dism.exe /online /enable-feature /featurename:$feature /all /norestart | Write-Host
            # Re-verificar o status após a tentativa de habilitação
            if (-not (Get-WindowsOptionalFeature -Online -FeatureName $feature -ErrorAction SilentlyContinue).State -eq "Enabled") {
                Write-Warning "Não foi possível habilitar o recurso '$feature'. Isso pode indicar um problema no sistema ou que um reinício é necessário."
                # Não aborta imediatamente, mas avisa. O wsl --install pode falhar depois.
            }
        }
    } else {
        Write-Success "Recursos de virtualização e WSL do Windows já estão habilitados."
    }

    # Agora, verifica o status geral do WSL e a instalação da distribuição Ubuntu
    $wslStatusOutput = (wsl --status 2>&1)
    $wslVersion2Default = $wslStatusOutput -like "*versão padrão: 2*"
    
    # Obtém todas as distribuições que contêm "Ubuntu" no nome
    # CORREÇÃO DA LÓGICA DE DETECÇÃO: Removendo caracteres nulos e usando -match
    $rawListOutput = wsl --list --quiet 2>&1
    $existingUbuntuDistros = @($rawListOutput | ForEach-Object { 
        # Remove all non-printable/control characters and then trim whitespace
        # \p{L} = Letter, \p{N} = Number, \s = Whitespace, \p{P} = Punctuation, '-' = Hyphen
        # [^\...] matches anything NOT in the specified set.
        $cleanedItem = [regex]::Replace($_, '[^\p{L}\p{N}\s\p{P}-]', '').Trim()
        Write-Host "DEBUG: Cleaned Item (Regex): '$cleanedItem' (Length: $($cleanedItem.Length))" -ForegroundColor DarkCyan
        $cleanedItem
    } | Where-Object { $_ -match "^Ubuntu" -and $_.Length -gt 0 }) | Sort-Object

    # --- DEBUGGING OUTPUT START ---
    Write-Host "DEBUG: rawListOutput contains $($rawListOutput.Count) elements." -ForegroundColor Magenta
    $rawListOutput | ForEach-Object { Write-Host "DEBUG: Raw Item: '$_'" -ForegroundColor Magenta }
    Write-Host "DEBUG: existingUbuntuDistros (after processing): $($existingUbuntuDistros -join ', ')" -ForegroundColor Magenta
    Write-Host "DEBUG: existingUbuntuDistros.Count: $($existingUbuntuDistros.Count)" -ForegroundColor Magenta
    # --- DEBUGGING OUTPUT END ---

    $script:UbuntuDistroName = $null # Nome da distro Ubuntu que o script usará
    $ubuntuInstalled = $false

    if ($existingUbuntuDistros.Count -eq 0) {
        # Nenhuma distro Ubuntu encontrada, vamos instalar a padrão
        Write-Info "Nenhuma distribuição Ubuntu encontrada. Instalando '$DesiredUbuntuDistroName'..."
        $script:UbuntuDistroName = $DesiredUbuntuDistroName
    } elseif ($existingUbuntuDistros.Count -eq 1) {
        # Apenas uma distro Ubuntu encontrada, vamos usá-la
        $script:UbuntuDistroName = $existingUbuntuDistros[0]
        Write-Success "Distribuição Ubuntu existente detectada: '$script:UbuntuDistroName'. O script a utilizará."
        $ubuntuInstalled = [bool]$true # CORREÇÃO AQUI
    } else { # Múltiplas distribuições Ubuntu encontradas
        Write-Warning "Múltiplas distribuições Ubuntu foram detectadas no WSL. O script tentará usar '$DesiredUbuntuDistroName'."
        Write-Host "Distribuições Ubuntu detectadas:" -ForegroundColor Yellow
        $existingUbuntuDistros | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
        
        # Tenta encontrar a distro DESEJADA (ex: "Ubuntu") na lista
        if ($existingUbuntuDistros -contains $DesiredUbuntuDistroName) {
            $script:UbuntuDistroName = $DesiredUbuntuDistroName
            Write-Success "A distribuição desejada ('$DesiredUbuntuDistroName') foi encontrada entre as existentes. O script a utilizará para o setup."
            $ubuntuInstalled = [bool]$true # CORREÇÃO AQUI
            # Informar o usuário que outras distros Ubuntu serão ignoradas pelo script para este setup
            Write-Info "Nota: Outras distribuições Ubuntu detectadas (como 'Ubuntu-22.04') serão ignoradas pelo script para este setup e permanecerão intocadas."
        } else {
            # Se a distro desejada NÃO ESTIVER entre as existentes, e há múltiplas outras
            Write-ErrorMsg "Múltiplas distribuições Ubuntu foram detectadas, mas a distribuição padrão esperada ('$DesiredUbuntuDistroName') não foi encontrada na lista. O script não pode prosseguir sem uma clara indicação."
            Write-ErrorMsg "Por favor, renomeie uma das suas distribuições existentes para '$DesiredUbuntuDistroName' (se for adequado) ou desinstale as não utilizadas."
            Write-Host "Para renomear (ex: se 'Ubuntu-22.04' for a que você quer usar como 'Ubuntu'):" -ForegroundColor Yellow
            Write-Host "  1. Exporte: wsl --export Ubuntu-22.04 C:\temp\ubuntu2204_backup.tar" -ForegroundColor Yellow
            Write-Host "  2. Desregistre a antiga: wsl --unregister Ubuntu-22.04" -ForegroundColor Yellow
            Write-Host "  3. Importe com o novo nome: wsl --import Ubuntu C:\wsl-distros\Ubuntu C:\temp\ubuntu2204_backup.tar" -ForegroundColor Yellow
            Write-Host "`nApós a correção, execute o script novamente." -ForegroundColor Yellow
            exit 1 # Aborta
        }
    }

    # Agora, prossegue com a instalação/configuração se necessário
    if (-not $ubuntuInstalled) {
        # Aqui, $script:UbuntuDistroName já está definido como $DesiredUbuntuDistroName
        Write-Info "Instalando a distribuição '$script:UbuntuDistroName' via WSL. Siga as instruções na nova janela se solicitado."
        try {
            wsl --install -d $script:UbuntuDistroName
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "O comando 'wsl --install' retornou um código de saída diferente de zero ($LASTEXITCODE). Isso pode acontecer se o Ubuntu já estiver parcialmente instalado ou se houver um erro."
            }
        }
        catch {
            Write-ErrorMsg "Falha ao instalar o Ubuntu via 'wsl --install'. Erro: $($_.Exception.Message)"
            return $false
        }
        # IMPORTANTE: Após wsl --install, pode abrir uma nova janela para criação de usuário.
        # O script precisa pausar e o usuário precisa FECHAR ESSA JANELA depois de criar o user.
        Pause-Script -Prompt "Uma nova janela do Ubuntu deve ter aberto (ou abrirá agora) para a criação do seu usuário e senha Linux. Por favor, complete essa etapa digitando seu nome de usuário e senha na janela do Ubuntu.`n`nAPÓS criar seu usuário e senha e ver o prompt do Linux (ex: 'seuusario@seuhost:~$), DIGITE 'exit' e pressione Enter naquela janela do Ubuntu para FECHÁ-LA.`n`nEntão, RETORNE A ESTA JANELA DO POWERSHELL e pressione qualquer tecla para continuar o setup."
    } else {
        # Ubuntu já está instalado. Certifique-se de que é WSL2.
        if (-not $wslVersion2Default) {
            Write-Info "A distribuição '$script:UbuntuDistroName' já está instalada, mas garantindo que a versão padrão do WSL seja a 2..."
            try {
                wsl --set-version $script:UbuntuDistroName 2
                wsl --set-default-version 2 # Define para que novas distros também sejam v2
                Write-Success "Versão padrão do WSL definida para 2 e '$script:UbuntuDistroName' configurado para WSL2."
            }
            catch {
                Write-ErrorMsg "Falha ao definir a versão do WSL para 2 para '$script:UbuntuDistroName' ou a versão padrão. Erro: $($_.Exception.Message)"
                return $false
            }
        } else {
            Write-Success "A distribuição '$script:UbuntuDistroName' já está instalada e configurada para WSL2."
        }
    }
    
    Pause-Script -Prompt "A instalação inicial do WSL2 e Ubuntu pode exigir um REINÍCIO do computador.`n`nApós o reinício, reabra este script (Instalador_Whisper.ps1) como Administrador."
    Write-Info "Por favor, reinicie seu computador AGORA, se solicitado pelo sistema."
    return $true
}

function Ensure-UbuntuIsReady {
    Write-Info "Garantindo que o Ubuntu esteja pronto para uso..."
    # Loop para tentar executar um comando no Ubuntu para verificar sua prontidão
    for ($i = 0; $i -lt 10; $i++) { # Tenta 10 vezes
        try {
            # Tenta executar um comando simples e ignora a saída, apenas verifica o sucesso
            wsl -d $script:UbuntuDistroName -- exec /bin/true 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Comunicação com o Ubuntu estabelecida."
                return $true # Ubuntu está pronto para comunicação
            }
        }
        catch {
            # Erro na comunicação, provavelmente o Ubuntu ainda não está totalmente inicializado ou o usuário não foi criado
            Write-Warning "Falha na comunicação inicial com o Ubuntu. Tentando novamente... ($($i+1)/10)"
        }
        Start-Sleep -Seconds 5 # Espera antes de tentar novamente
    }

    # Se a comunicação falhou após várias tentativas, o usuário/senha pode não ter sido criado
    Write-Warning "O Ubuntu parece estar funcionando, mas pode precisar de configuração inicial (usuário/senha)."
    # Mensagem atualizada para o caso de o usuário já ter criado o user/senha
    Pause-Script -Prompt "Uma janela do Ubuntu pode ter se aberto para a criação de usuário e senha anteriormente. Se você JÁ criou seu usuário e senha, por favor, apenas pressione uma tecla NESTA janela do PowerShell para continuar. Caso contrário, uma janela do Ubuntu pode abrir para isso (e você deverá digitar 'exit' e Enter nela após configurar)."

    # Após a pausa e (esperançosamente) a criação do usuário, tenta comunicar novamente
    for ($i = 0; $i -lt 5; $i++) { # Tenta mais 5 vezes para verificar
        try {
            wsl -d $script:UbuntuDistroName -- exec /bin/true 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Comunicação com o Ubuntu estabelecida após configuração manual."
                return $true
            }
        }
        catch {
            Write-Warning "Falha na comunicação pós-configuração. Tentando novamente... ($($i+1)/5)"
        }
        Start-Sleep -Seconds 5
    }

    Write-ErrorMsg "Não foi possível estabelecer comunicação com o Ubuntu após a configuração inicial. Verifique o status do WSL e do Ubuntu."
    return $false
}


function Clone-RepoInWSL {
    Write-Info "Clonando o repositório '$RepoUrl' no WSL..."
    # Usar 'whoami' para obter o nome de usuário atual do WSL para evitar problemas de HOME
    $wslUser = (wsl -d $script:UbuntuDistroName -- whoami 2>&1).Trim()
    if ([string]::IsNullOrWhiteSpace($wslUser)) {
        Write-ErrorMsg "Não foi possível determinar o usuário padrão no WSL para a distribuição '$script:UbuntuDistroName'. Verifique se o usuário existe e tem um HOME válido."
        Write-Warning "Tentando usar 'root' como usuário e '/tmp' como diretório para clonagem."
        $wslUser = "root"
        $wslHome = "/tmp"
    } else {
        $wslHome = (wsl -d $script:UbuntuDistroName -u $wslUser -- exec printenv HOME 2>&1).Trim()
        if ([string]::IsNullOrWhiteSpace($wslHome)) {
            Write-ErrorMsg "Não foi possível determinar o diretório HOME para o usuário '$wslUser' no WSL. Verifique a configuração do seu Ubuntu."
            Write-Warning "Tentando usar '/tmp' como diretório para clonagem."
            $wslHome = "/tmp"
        }
    }


    $targetPath = "$wslHome/$RepoDir"
    
    # CORREÇÃO: Usar $LASTEXITCODE para verificar a existência do diretório de forma mais robusta
    Write-Host "DEBUG: Checking if directory '$targetPath' exists..." -ForegroundColor DarkCyan
    wsl -d $script:UbuntuDistroName -u $wslUser -- exec test -d "$targetPath" 2>&1 | Out-Null # Redireciona stderr para null
    $dirExists = ($LASTEXITCODE -eq 0) # true se o diretório existe, false caso contrário
    Write-Host "DEBUG: Directory exists check result: $dirExists (LASTEXITCODE: $LASTEXITCODE)" -ForegroundColor DarkCyan


    if ($dirExists) {
        Write-Success "Diretório '$targetPath' já existe no WSL. Pulando clonagem."
        # Adiciona debug para listar o conteúdo mesmo se já existir
        Write-Host "DEBUG: Listing contents of existing directory: '$targetPath'" -ForegroundColor DarkCyan
        wsl -d $script:UbuntuDistroName -u $wslUser -- ls -la "$targetPath" 2>&1 | Write-Host -ForegroundColor DarkCyan
        Write-Host "DEBUG: Finished listing contents of existing directory." -ForegroundColor DarkCyan
        return $true
    }

    try {
        # Clonar o repositório
        wsl -d $script:UbuntuDistroName -u $wslUser -- git clone $RepoUrl $targetPath 2>&1 | Write-Host
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "Falha ao clonar o repositório '$RepoUrl' para '$targetPath'. Código de saída: $LASTEXITCODE."
            Write-Warning "Verifique se o git está instalado no Ubuntu ou se há problemas de rede/permissão."
            return $false
        }
        Write-Success "Repositório clonado com sucesso para '$targetPath'."
        # Adiciona debug para listar o conteúdo após a clonagem
        Write-Host "DEBUG: Listing contents of newly cloned directory: '$targetPath'" -ForegroundColor DarkCyan
        wsl -d $script:UbuntuDistroName -u $wslUser -- ls -la "$targetPath" 2>&1 | Write-Host -ForegroundColor DarkCyan
        Write-Host "DEBUG: Finished listing contents of newly cloned directory." -ForegroundColor DarkCyan
        return $true
    }
    catch {
        Write-ErrorMsg "Erro ao clonar o repositório: $($_.Exception.Message)"
        return $false
    }
}

function Run-ProjectSetupInWSL {
    Write-Info "Executando o script de setup do projeto ('setup.sh') no WSL..."
    $wslUser = (wsl -d $script:UbuntuDistroName -- whoami 2>&1).Trim()
    if ([string]::IsNullOrWhiteSpace($wslUser)) {
        Write-ErrorMsg "Não foi possível determinar o usuário padrão no WSL. Abortando execução do setup.sh."
        return $false
    }

    $wslHome = (wsl -d $script:UbuntuDistroName -u $wslUser -- exec printenv HOME 2>&1).Trim()
    $setupScriptPath = "$wslHome/$RepoDir/setup.sh"
    Write-Host "DEBUG: Looking for setup.sh at: '$setupScriptPath'" -ForegroundColor DarkCyan # NOVA LINHA DE DEBUG

    # CORREÇÃO: Usar $LASTEXITCODE para verificar a existência do arquivo de forma mais robusta
    Write-Host "DEBUG: Verifying existence of setup.sh with test -f..." -ForegroundColor DarkCyan
    wsl -d $script:UbuntuDistroName -u $wslUser -- exec test -f "$setupScriptPath" 2>&1 | Out-Null # Redireciona stderr para null
    $fileExists = ($LASTEXITCODE -eq 0) # true se o arquivo existe, false caso contrário
    Write-Host "DEBUG: File exists check result: $fileExists (LASTEXITCODE: $LASTEXITCODE)" -ForegroundColor DarkCyan

    if (-not $fileExists) {
        Write-ErrorMsg "O arquivo 'setup.sh' não foi encontrado em '$setupScriptPath' dentro do WSL. Verifique se o repositório foi clonado corretamente."
        # Adiciona debug para listar o conteúdo do diretório onde 'setup.sh' deveria estar
        Write-Host "DEBUG: Listing contents of directory where setup.sh should be: '$wslHome/$RepoDir'" -ForegroundColor DarkCyan
        wsl -d $script:UbuntuDistroName -u $wslUser -- ls -la "$wslHome/$RepoDir" 2>&1 | Write-Host -ForegroundColor DarkCyan # NOVA LINHA DE DEBUG
        Write-Host "DEBUG: Finished listing contents of directory." -ForegroundColor DarkCyan
        return $false
    }

    try {
        # Dar permissão de execução ao script
        wsl -d $script:UbuntuDistroName -u $wslUser -- chmod +x "$setupScriptPath" 2>&1 | Out-Null
        
        # Executar o script de setup.sh
        # Nota: O setup.sh pode levar um tempo para baixar imagens Docker e configurar.
        Write-Info "Iniciando 'setup.sh'. Este processo pode levar vários minutos, dependendo da sua conexão com a internet e hardware."
        wsl -d $script:UbuntuDistroName -u $wslUser -- "$setupScriptPath" 2>&1 | Write-Host
        
        if ($LASTEXITCODE -ne 0) {
            Write-ErrorMsg "O script 'setup.sh' retornou um erro (código de saída: $LASTEXITCODE). Verifique o log '$setupScriptPath.log' dentro do Ubuntu para mais detalhes."
            return $false
        }
        Write-Success "Script 'setup.sh' executado com sucesso."
        return $true
    }
    catch {
        Write-ErrorMsg "Erro ao executar o script 'setup.sh': $($_.Exception.Message)"
        return $false
    }
}

# --- Função Principal ---
function Main {
    Write-Header "Instalador e Configuração do Whisper Transcriber"

    if (-not (Check-ExecutionPolicy)) {
        Pause-Script "Pressione qualquer tecla para sair."
        exit 1
    }

    if (-not (Check-AdminPrivileges)) {
        Pause-Script "Pressione qualquer tecla para sair."
        exit 1
    }

    # A função Install-WSL2 agora lida com múltiplos Ubuntus e a instalação inicial.
    if (-not (Install-WSL2)) {
        Write-ErrorMsg "Falha na instalação/configuração inicial do WSL2 e Ubuntu. Abortando."
        Pause-Script "Pressione qualquer tecla para sair."
        exit 1
    }

    # Somente se Install-WSL2 retornar TRUE (sucesso na instalação ou detecção)
    Write-Info "Verificação de Ubuntu iniciada."

    # Após o possível reinício e nova execução do script, garantimos que o Ubuntu esteja pronto.
    if (-not (Ensure-UbuntuIsReady)) {
        Write-ErrorMsg "O Ubuntu não está pronto para comunicação. Por favor, verifique manualmente o status do WSL (wsl --list --verbose) e tente iniciar sua distribuição Ubuntu."
        Pause-Script "Pressione qualquer tecla para sair."
        exit 1
    }

    if (-not (Clone-RepoInWSL)) {
        Write-ErrorMsg "Falha ao clonar o repositório. Abortando."
        Pause-Script "Pressione qualquer tecla para sair."
        exit 1
    }

    if (-not (Run-ProjectSetupInWSL)) {
        Write-ErrorMsg "Falha ao executar o script de setup do projeto. Abortando."
        Pause-Script "Pressione qualquer tecla para sair."
        exit 1
    }

    Write-Success "O setup do Whisper Transcriber foi concluído com sucesso!"
    Write-Info "Você pode encontrar a pasta 'transcribe' e o script 'setup.sh' dentro do seu Ubuntu no WSL."
    Write-Info "Para usar a ferramenta, abra o terminal do Ubuntu (WSL) e siga as instruções fornecidas pelo 'setup.sh' (comando 'whisper-transcribe')."
    Write-Info "Lembre-se de colocar seus arquivos de vídeo na pasta 'videos' dentro da pasta transcribe criada no seu Ubuntu WSL"
    Pause-Script "Pressione qualquer tecla para sair do instalador."
}

# --- Execução do Script ---
Main
