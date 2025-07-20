@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================================
:: 🎙️ Whisper Transcriber - Instalador Inteligente para Windows
:: ============================================================================
:: VERSÃO: 2.0 - Corrigida e Documentada
:: 
:: FUNCIONALIDADES:
:: - Detecta automaticamente a melhor forma de instalar
:: - Se Docker Desktop existe: usa ele (método simples)
:: - Se não existe: instala WSL2 + Ubuntu + Docker nativo (método leve)
:: - Verifica instalações existentes e oferece atualização
:: - Tratamento robusto de erros
:: - Feedback visual completo
::
:: REQUISITOS:
:: - Windows 10 versão 2004+ ou Windows 11
:: - Privilégios de Administrador
:: - Conexão com internet
::
:: TESTADO EM:
:: - Windows 10 21H2
:: - Windows 11 22H2
:: ============================================================================

:: Configurações globais
set "SCRIPT_VERSION=2.0"
set "PROJECT_NAME=Whisper Transcriber"
set "REPO_URL=https://github.com/malvesro/transcribe.git"
set "COMPOSE_CMD="

:: Função para log com timestamp
call :log_info "Iniciando %PROJECT_NAME% Instalador v%SCRIPT_VERSION%"

:: Exibir cabeçalho
echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                🎙️ %PROJECT_NAME% - Instalador para Windows
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo ✨ Este instalador escolherá automaticamente a melhor opção para você!
echo 📋 Versão: %SCRIPT_VERSION%
echo.

:: ============================================================================
:: VERIFICAÇÕES INICIAIS
:: ============================================================================

call :log_info "Iniciando verificações iniciais"

:: Verificar privilégios de administrador
call :check_admin
if errorlevel 1 exit /b 1

:: Verificar versão do Windows
call :check_windows_version
if errorlevel 1 exit /b 1

:: Verificar conexão com internet
call :check_internet
if errorlevel 1 exit /b 1

:: ============================================================================
:: DETECÇÃO DE INSTALAÇÃO EXISTENTE
:: ============================================================================

call :log_info "Verificando instalação existente"

:: Verificar se o projeto já existe
echo 🔍 Verificando se o projeto já existe...
if exist "transcriber_web_app" (
    echo ✅ Projeto já existe!
    call :update_existing_project
    goto :end_success
)

if exist "transcribe" (
    echo ✅ Projeto encontrado em subdiretório!
    cd /d "transcribe" 2>nul
    if errorlevel 1 (
        call :log_error "Erro ao acessar diretório do projeto"
        goto :end_error
    )
    call :update_existing_project
    goto :end_success
)

:: ============================================================================
:: DETECÇÃO DO MÉTODO DE INSTALAÇÃO
:: ============================================================================

call :log_info "Detectando método de instalação"

echo 🔍 Detectando melhor método de instalação...
echo.

:: Verificar se Docker Desktop está instalado e funcionando
call :check_docker_desktop
set "docker_status=%errorlevel%"

if %docker_status% equ 0 (
    echo ✅ Docker Desktop encontrado e funcionando!
    echo 🎯 Usando Docker Desktop (método simples)
    call :install_with_docker_desktop
    goto :end_success
) else if %docker_status% equ 2 (
    echo ⚠️  Docker Desktop instalado mas não está rodando
    echo.
    echo 🚀 Por favor:
    echo    1. Abra o Docker Desktop
    echo    2. Aguarde ele inicializar completamente
    echo    3. Execute este script novamente
    echo.
    pause
    goto :end_error
) else (
    echo 📦 Docker Desktop não encontrado
    echo 🎯 Usando WSL2 + Ubuntu + Docker nativo (método leve)
    echo.
    echo 🔧 O que será instalado:
    echo    • WSL2 (Subsistema Linux para Windows)
    echo    • Ubuntu (sistema Linux leve)
    echo    • Docker nativo (dentro do Ubuntu)
    echo    • %PROJECT_NAME%
    echo.
    call :install_with_wsl
    goto :end_success
)

:: ============================================================================
:: FUNÇÕES DE INSTALAÇÃO
:: ============================================================================

:update_existing_project
call :log_info "Atualizando projeto existente"
echo 🔄 Atualizando projeto existente...

:: Detectar se está usando WSL ou Docker Desktop
wsl -d Ubuntu -- test -d ~/transcribe >nul 2>&1
if not errorlevel 1 (
    echo 🐧 Detectado: instalação via WSL2
    call :update_via_wsl
) else (
    echo 🐳 Detectado: instalação via Docker Desktop
    call :update_via_docker_desktop
)
goto :eof

:update_via_wsl
call :log_info "Atualizando via WSL2"
echo 🔄 Atualizando via WSL2...

:: Verificar se WSL está funcionando
wsl --status >nul 2>&1
if errorlevel 1 (
    call :log_error "WSL não está funcionando"
    echo ❌ ERRO: WSL não está funcionando
    echo 💡 Tente reiniciar o computador e executar novamente
    pause
    exit /b 1
)

:: Atualizar projeto no WSL
echo ⏳ Atualizando código e reiniciando serviços...
wsl -d Ubuntu -- bash -c "cd ~/transcribe 2>/dev/null || cd ~/transcribe* 2>/dev/null || (echo 'Projeto não encontrado no WSL' && exit 1)"
if errorlevel 1 (
    call :log_error "Projeto não encontrado no WSL"
    echo ❌ ERRO: Projeto não encontrado no WSL
    pause
    exit /b 1
)

wsl -d Ubuntu -- bash -c "cd ~/transcribe* && git pull && docker compose up --build -d"
if errorlevel 1 (
    call :log_error "Falha ao atualizar via WSL"
    echo ❌ ERRO: Falha ao atualizar via WSL
    echo 💡 Verifique se o Docker está funcionando no Ubuntu
    pause
    exit /b 1
)

echo ✅ Atualização via WSL2 concluída!
goto :eof

:update_via_docker_desktop
call :log_info "Atualizando via Docker Desktop"
echo 🔄 Atualizando via Docker Desktop...

:: Verificar se Docker está funcionando
docker info >nul 2>&1
if errorlevel 1 (
    call :log_error "Docker Desktop não está rodando"
    echo ❌ ERRO: Docker Desktop não está rodando!
    echo 🚀 Por favor, abra o Docker Desktop e tente novamente
    pause
    exit /b 1
)

:: Atualizar via git se possível
if exist ".git" (
    echo 📥 Atualizando código via git...
    git pull >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Código atualizado via git!
    ) else (
        echo ⚠️  Não foi possível atualizar via git, continuando...
    )
) else (
    echo ⚠️  Repositório git não encontrado, pulando atualização de código...
)

:: Reiniciar serviços
echo 🔄 Reiniciando serviços...
docker compose down >nul 2>&1
docker compose up --build -d
if errorlevel 1 (
    call :log_error "Falha ao reiniciar serviços"
    echo ❌ ERRO: Falha ao reiniciar serviços
    echo 💡 Verifique os logs: docker compose logs
    pause
    exit /b 1
)

echo ✅ Atualização via Docker Desktop concluída!
goto :eof

:install_with_docker_desktop
call :log_info "Instalando com Docker Desktop"
echo.
echo 🐳 Instalando com Docker Desktop...

:: Verificar Docker Compose
call :check_docker_compose
if errorlevel 1 goto :end_error

:: Criar diretório temporário para download
set "TEMP_DIR=%TEMP%\whisper_transcriber_%RANDOM%"
mkdir "%TEMP_DIR%" 2>nul
if errorlevel 1 (
    call :log_error "Falha ao criar diretório temporário"
    echo ❌ ERRO: Falha ao criar diretório temporário
    pause
    exit /b 1
)

:: Baixar projeto
echo 📥 Baixando projeto...
echo ⏳ Isso pode levar alguns minutos dependendo da sua conexão...
cd /d "%TEMP_DIR%"
git clone "%REPO_URL%" transcribe
if errorlevel 1 (
    call :log_error "Falha ao baixar projeto"
    echo ❌ ERRO: Falha ao baixar projeto
    echo 💡 Verifique sua conexão com a internet
    rmdir /s /q "%TEMP_DIR%" 2>nul
    pause
    exit /b 1
)
echo ✅ Projeto baixado com sucesso!

:: Mover projeto para diretório atual
cd /d "%~dp0"
if exist "transcribe" (
    echo ⚠️  Diretório transcribe já existe, criando backup...
    if exist "transcribe_backup" rmdir /s /q "transcribe_backup" 2>nul
    move "transcribe" "transcribe_backup" >nul 2>&1
)

move "%TEMP_DIR%\transcribe" "transcribe" >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao mover projeto"
    echo ❌ ERRO: Falha ao mover projeto
    rmdir /s /q "%TEMP_DIR%" 2>nul
    pause
    exit /b 1
)

:: Limpar diretório temporário
rmdir /s /q "%TEMP_DIR%" 2>nul

:: Entrar no diretório do projeto
cd /d "transcribe"
if errorlevel 1 (
    call :log_error "Falha ao acessar diretório do projeto"
    echo ❌ ERRO: Falha ao acessar diretório do projeto
    pause
    exit /b 1
)

:: Criar diretórios necessários
call :create_directories
if errorlevel 1 goto :end_error

:: Configurar ambiente
call :setup_environment
if errorlevel 1 goto :end_error

:: Iniciar serviços
call :start_services_docker
if errorlevel 1 goto :end_error

goto :eof

:install_with_wsl
call :log_info "Instalando com WSL2"
echo.
echo 🐧 Instalando com WSL2...

:: Verificar e instalar WSL2
call :setup_wsl2
if errorlevel 1 goto :end_error

:: Verificar e instalar Ubuntu
call :setup_ubuntu
if errorlevel 1 goto :end_error

:: Verificar e instalar Docker no Ubuntu
call :setup_docker_ubuntu
if errorlevel 1 goto :end_error

:: Instalar projeto no Ubuntu
call :install_project_ubuntu
if errorlevel 1 goto :end_error

goto :eof

:: ============================================================================
:: FUNÇÕES DE VERIFICAÇÃO
:: ============================================================================

:check_admin
echo 🔍 Verificando privilégios de administrador...
net session >nul 2>&1
if errorlevel 1 (
    call :log_error "Script não está sendo executado como administrador"
    echo ❌ ERRO: Este script precisa ser executado como Administrador
    echo.
    echo 🔧 Como executar como Administrador:
    echo    1. Clique com botão direito neste arquivo
    echo    2. Selecione "Executar como administrador"
    echo    3. Clique "Sim" quando perguntado
    echo.
    pause
    exit /b 1
)
echo ✅ Executando como Administrador - OK!
goto :eof

:check_windows_version
echo 🔍 Verificando versão do Windows...
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
for /f "tokens=1 delims=." %%a in ("%VERSION%") do set MAJOR=%%a
for /f "tokens=2 delims=." %%a in ("%VERSION%") do set MINOR=%%a

if %MAJOR% LSS 10 (
    call :log_error "Versão do Windows não suportada"
    echo ❌ ERRO: Windows muito antigo!
    echo    Precisa do Windows 10 versão 2004 ou superior
    echo    Ou Windows 11 qualquer versão
    pause
    exit /b 1
)

if %MAJOR% EQU 10 if %MINOR% LSS 19041 (
    call :log_error "Build do Windows 10 muito antigo"
    echo ❌ ERRO: Windows 10 muito antigo!
    echo    Precisa da versão 2004 (build 19041) ou superior
    echo    💡 Atualize o Windows e tente novamente
    pause
    exit /b 1
)

echo ✅ Versão do Windows compatível! (Build: %VERSION%)
goto :eof

:check_internet
echo 🔍 Verificando conexão com internet...
ping -n 1 8.8.8.8 >nul 2>&1
if errorlevel 1 (
    ping -n 1 1.1.1.1 >nul 2>&1
    if errorlevel 1 (
        call :log_error "Sem conexão com internet"
        echo ❌ ERRO: Sem conexão com internet
        echo 💡 Verifique sua conexão e tente novamente
        pause
        exit /b 1
    )
)
echo ✅ Conexão com internet OK!
goto :eof

:check_docker_desktop
:: Retorna: 0=funcionando, 1=não instalado, 2=instalado mas não rodando
docker info >nul 2>&1
if not errorlevel 1 (
    exit /b 0
)

docker --version >nul 2>&1
if not errorlevel 1 (
    exit /b 2
)

exit /b 1

:check_docker_compose
echo 🔍 Verificando Docker Compose...
docker compose version >nul 2>&1
if not errorlevel 1 (
    set "COMPOSE_CMD=docker compose"
    echo ✅ Docker Compose v2 encontrado!
    exit /b 0
)

docker-compose --version >nul 2>&1
if not errorlevel 1 (
    set "COMPOSE_CMD=docker-compose"
    echo ✅ Docker Compose v1 encontrado!
    exit /b 0
)

call :log_error "Docker Compose não encontrado"
echo ❌ ERRO: Docker Compose não encontrado!
echo 📥 Por favor, atualize o Docker Desktop para a versão mais recente
echo    👉 https://www.docker.com/products/docker-desktop/
pause
exit /b 1

:: ============================================================================
:: FUNÇÕES DE CONFIGURAÇÃO WSL2
:: ============================================================================

:setup_wsl2
echo 🔍 Verificando WSL2...
wsl --status >nul 2>&1
if not errorlevel 1 (
    echo ✅ WSL2 já está instalado!
    goto :eof
)

echo 📦 Instalando WSL2...
echo ⏳ Isso pode levar alguns minutos...
echo.
echo 📊 Progresso WSL2:
echo    [1/3] 🔧 Habilitando Subsistema Linux...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao habilitar Subsistema Linux"
    echo ❌ ERRO: Falha ao habilitar Subsistema Linux
    pause
    exit /b 1
)

echo    [2/3] 🔧 Habilitando Plataforma de Máquina Virtual...
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao habilitar Plataforma de Máquina Virtual"
    echo ❌ ERRO: Falha ao habilitar Plataforma de Máquina Virtual
    pause
    exit /b 1
)

echo    [3/3] ⚙️ Configurando WSL2 como padrão...
wsl --set-default-version 2 >nul 2>&1

echo ✅ WSL2 configurado com sucesso!
goto :eof

:setup_ubuntu
echo 🔍 Verificando Ubuntu...
wsl -l -v | findstr Ubuntu >nul 2>&1
if not errorlevel 1 (
    echo ✅ Ubuntu já está instalado!
    goto :eof
)

echo 📦 Instalando Ubuntu...
echo ⏳ Baixando e instalando Ubuntu (pode levar 5-10 minutos)...
echo 💡 Aguarde, o processo está rodando em segundo plano...

wsl --install -d Ubuntu --no-launch
if errorlevel 1 (
    call :log_error "Falha ao instalar Ubuntu"
    echo ❌ ERRO: Falha ao instalar Ubuntu
    echo 💡 Tente executar manualmente: wsl --install -d Ubuntu
    pause
    exit /b 1
)

echo ✅ Ubuntu instalado com sucesso!
timeout /t 5 /nobreak >nul
goto :eof

:setup_docker_ubuntu
echo 🔍 Verificando Docker no Ubuntu...
wsl -d Ubuntu -- docker --version >nul 2>&1
if not errorlevel 1 (
    echo ✅ Docker já está instalado no Ubuntu!
    goto :eof
)

echo 📦 Instalando Docker no Ubuntu...
echo ⏳ Isso pode levar 5-10 minutos...
echo.
echo 📊 Progresso Docker:
echo    [1/5] 📦 Atualizando repositórios...
wsl -d Ubuntu -- bash -c "sudo apt update" >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao atualizar repositórios"
    echo ❌ ERRO: Falha ao atualizar repositórios
    pause
    exit /b 1
)

echo    [2/5] 📥 Baixando Docker...
wsl -d Ubuntu -- bash -c "sudo apt install -y docker.io" >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao instalar Docker"
    echo ❌ ERRO: Falha ao instalar Docker
    pause
    exit /b 1
)

echo    [3/5] 📥 Instalando Docker Compose...
wsl -d Ubuntu -- bash -c "sudo apt install -y docker-compose" >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao instalar Docker Compose"
    echo ❌ ERRO: Falha ao instalar Docker Compose
    pause
    exit /b 1
)

echo    [4/5] ⚙️ Configurando Docker...
wsl -d Ubuntu -- bash -c "sudo systemctl enable docker && sudo systemctl start docker" >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao configurar Docker"
    echo ❌ ERRO: Falha ao configurar Docker
    pause
    exit /b 1
)

echo    [5/5] 👤 Configurando usuário...
wsl -d Ubuntu -- bash -c "sudo usermod -aG docker \$USER" >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao configurar usuário Docker"
    echo ❌ ERRO: Falha ao configurar usuário Docker
    pause
    exit /b 1
)

echo ✅ Docker instalado e configurado com sucesso!
goto :eof

:install_project_ubuntu
echo 📥 Instalando projeto no Ubuntu...
echo ⏳ Baixando código e configurando ambiente...

:: Verificar se projeto já existe no Ubuntu
wsl -d Ubuntu -- test -d ~/transcribe >nul 2>&1
if not errorlevel 1 (
    echo ✅ Projeto já existe! Atualizando...
    wsl -d Ubuntu -- bash -c "cd ~/transcribe && git pull && docker compose up --build -d"
    if errorlevel 1 (
        call :log_error "Falha ao atualizar projeto no Ubuntu"
        echo ❌ ERRO: Falha ao atualizar projeto no Ubuntu
        pause
        exit /b 1
    )
    goto :eof
)

:: Instalar projeto no Ubuntu
wsl -d Ubuntu -- bash -c "cd ~ && git clone %REPO_URL% && cd transcribe && mkdir -p transcriber_web_app/videos transcriber_web_app/results && echo 'MAX_FILE_SIZE_GB=15' > .env && echo 'FLASK_ENV=development' >> .env && echo 'COMPOSE_PROJECT_NAME=transcribe' >> .env && docker compose up --build -d"
if errorlevel 1 (
    call :log_error "Falha ao instalar projeto no Ubuntu"
    echo ❌ ERRO: Falha ao instalar projeto no Ubuntu
    echo 💡 Verifique se o Docker está funcionando: wsl -d Ubuntu -- docker info
    pause
    exit /b 1
)

echo ✅ Projeto instalado com sucesso no Ubuntu!
goto :eof

:: ============================================================================
:: FUNÇÕES AUXILIARES
:: ============================================================================

:create_directories
echo 📁 Criando diretórios necessários...
if not exist "transcriber_web_app\videos" mkdir "transcriber_web_app\videos"
if not exist "transcriber_web_app\results" mkdir "transcriber_web_app\results"
if errorlevel 1 (
    call :log_error "Falha ao criar diretórios"
    echo ❌ ERRO: Falha ao criar diretórios
    exit /b 1
)
echo ✅ Diretórios criados!
goto :eof

:setup_environment
echo ⚙️ Configurando ambiente...
if not exist ".env" (
    echo MAX_FILE_SIZE_GB=15 > .env
    echo FLASK_ENV=development >> .env
    echo COMPOSE_PROJECT_NAME=transcribe >> .env
    if errorlevel 1 (
        call :log_error "Falha ao criar arquivo .env"
        echo ❌ ERRO: Falha ao criar arquivo .env
        exit /b 1
    )
    echo ✅ Arquivo .env criado com limite de 15GB
) else (
    echo ✅ Arquivo .env já existe
)
goto :eof

:start_services_docker
echo 🚀 Iniciando serviços...
echo ⏳ Baixando imagens Docker e construindo containers...
echo 💡 Isso pode levar 5-15 minutos na primeira vez
echo.
echo 📊 Progresso:
echo    [1/3] 📥 Baixando imagens base...
%COMPOSE_CMD% pull >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Algumas imagens podem não estar disponíveis, continuando...
)

echo    [2/3] 🏗️  Construindo aplicação...
%COMPOSE_CMD% build >nul 2>&1
if errorlevel 1 (
    call :log_error "Falha ao construir aplicação"
    echo ❌ ERRO: Falha ao construir aplicação
    echo 💡 Verifique os logs: %COMPOSE_CMD% logs
    exit /b 1
)

echo    [3/3] 🚀 Iniciando serviços...
%COMPOSE_CMD% up -d
if errorlevel 1 (
    call :log_error "Falha ao iniciar serviços"
    echo ❌ ERRO: Falha ao iniciar serviços
    echo 💡 Tentando diagnóstico...
    %COMPOSE_CMD% logs
    exit /b 1
)

echo ✅ Serviços iniciados com sucesso!
goto :eof

:: ============================================================================
:: FUNÇÕES DE LOG E UTILIDADES
:: ============================================================================

:log_info
echo [%date% %time%] INFO: %~1 >> "%~dp0install.log"
goto :eof

:log_error
echo [%date% %time%] ERROR: %~1 >> "%~dp0install.log"
goto :eof

:: ============================================================================
:: FINALIZAÇÕES
:: ============================================================================

:end_success
call :log_info "Instalação concluída com sucesso"
echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                        ✅ INSTALAÇÃO CONCLUÍDA!
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo 🎉 O %PROJECT_NAME% está funcionando!
echo 🌐 ACESSE AGORA: http://localhost:5000
echo.

:: Detectar método usado para instruções específicas
wsl -d Ubuntu -- test -d ~/transcribe >nul 2>&1
if not errorlevel 1 (
    echo 📋 Instalação via WSL2 - Comandos úteis:
    echo    🚀 Iniciar: wsl -d Ubuntu -- bash ~/transcribe/start-whisper.sh
    echo    ⏹️  Parar:   wsl -d Ubuntu -- bash ~/transcribe/stop-whisper.sh
    echo    📁 Arquivos: wsl -d Ubuntu -- explorer.exe ~/transcribe/transcriber_web_app/videos/
    echo    📜 Logs:    wsl -d Ubuntu -- bash ~/transcribe/logs-whisper.sh
) else (
    echo 📋 Instalação via Docker Desktop - Comandos úteis:
    echo    🚀 Iniciar: docker compose up -d
    echo    ⏹️  Parar:   docker compose down
    echo    📁 Arquivos: .\transcriber_web_app\videos\
    echo    📜 Logs:    docker compose logs -f
)

echo.
echo 💡 Dicas:
echo    • Para alterar limite de arquivo: edite o arquivo .env
echo    • Para ver logs: consulte os comandos acima
echo    • Para suporte: https://github.com/malvesro/transcribe/issues
echo.

:: Tentar abrir navegador
echo 🚀 Abrindo navegador...
timeout /t 3 /nobreak >nul
start http://localhost:5000 2>nul

echo.
echo 📋 Log de instalação salvo em: %~dp0install.log
echo.
echo Pressione qualquer tecla para sair...
pause >nul
exit /b 0

:end_error
call :log_error "Instalação falhou"
echo.
echo ❌ INSTALAÇÃO FALHOU!
echo.
echo 📋 Log de erros salvo em: %~dp0install.log
echo 💡 Para suporte, compartilhe este log em:
echo    👉 https://github.com/malvesro/transcribe/issues
echo.
pause
exit /b 1