# ============================================================================
# 🎙️ Whisper Transcriber - Instalação Super Fácil para Windows
# ============================================================================
# Este script instala TUDO automaticamente usando WSL2 + Ubuntu
# Não precisa do Docker Desktop - muito mais simples!
# Versão: 3.0 - WSL2 + Ubuntu + Docker
# ============================================================================

# Configurar codificação para UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Verificar se está executando como administrador
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ ERRO: Este script precisa ser executado como Administrador" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔧 Como executar como Administrador:" -ForegroundColor Yellow
    Write-Host "   1. Clique com botão direito no PowerShell" -ForegroundColor Yellow
    Write-Host "   2. Selecione 'Executar como administrador'" -ForegroundColor Yellow
    Write-Host "   3. Execute este script novamente" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Função para imprimir cabeçalho
function Write-Header {
    Write-Host ""
    Write-Host "████████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "                🎙️ Whisper Transcriber - Instalador Super Fácil" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✨ Este instalador fará TUDO automaticamente para você!" -ForegroundColor Green
    Write-Host "📋 Não precisa instalar nada manualmente - deixe conosco!" -ForegroundColor Blue
    Write-Host ""
    Write-Host "🔧 O que será instalado:" -ForegroundColor Blue
    Write-Host "   • WSL2 (Subsistema Linux para Windows)" -ForegroundColor Blue
    Write-Host "   • Ubuntu (sistema Linux leve)" -ForegroundColor Blue
    Write-Host "   • Docker (dentro do Ubuntu)" -ForegroundColor Blue
    Write-Host "   • Whisper Transcriber (nossa ferramenta)" -ForegroundColor Blue
    Write-Host ""
}

# Função para verificar versão do Windows
function Test-WindowsVersion {
    Write-Host "🔍 Verificando versão do Windows..." -ForegroundColor Blue
    
    $version = [System.Environment]::OSVersion.Version
    $build = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
    
    if ($version.Major -lt 10) {
        Write-Host "❌ ERRO: Windows muito antigo!" -ForegroundColor Red
        Write-Host "   Precisa do Windows 10 versão 2004 ou superior" -ForegroundColor Red
        Write-Host "   Ou Windows 11 qualquer versão" -ForegroundColor Red
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    
    if ($version.Major -eq 10 -and $build -lt 19041) {
        Write-Host "❌ ERRO: Windows 10 muito antigo!" -ForegroundColor Red
        Write-Host "   Precisa da versão 2004 (build 19041) ou superior" -ForegroundColor Red
        Write-Host "   💡 Atualize o Windows e tente novamente" -ForegroundColor Yellow
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    
    Write-Host "✅ Versão do Windows compatível!" -ForegroundColor Green
}

# Função para habilitar WSL2
function Enable-WSL2 {
    Write-Host ""
    Write-Host "🔧 Habilitando WSL2..." -ForegroundColor Blue
    Write-Host "⏳ Isso pode levar alguns minutos..." -ForegroundColor Yellow
    
    try {
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
        Write-Host "✅ Recursos do WSL2 habilitados!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ ERRO: Falha ao habilitar WSL2" -ForegroundColor Red
        Write-Host "💡 Tente executar manualmente no PowerShell como Admin:" -ForegroundColor Yellow
        Write-Host "   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" -ForegroundColor Yellow
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    
    # Definir WSL2 como padrão
    Write-Host "🔧 Configurando WSL2 como padrão..." -ForegroundColor Blue
    wsl --set-default-version 2 | Out-Null
}

# Função para instalar Ubuntu
function Install-Ubuntu {
    Write-Host ""
    Write-Host "🐧 Instalando Ubuntu..." -ForegroundColor Blue
    Write-Host "⏳ Isso pode levar alguns minutos..." -ForegroundColor Yellow
    
    try {
        wsl --install -d Ubuntu --no-launch 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "⚠️  Tentando método alternativo..." -ForegroundColor Yellow
            wsl --install Ubuntu --no-launch 2>$null
        }
        Write-Host "✅ Ubuntu instalado!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ ERRO: Falha ao instalar Ubuntu" -ForegroundColor Red
        Write-Host "💡 Tente executar manualmente: wsl --install -d Ubuntu" -ForegroundColor Yellow
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    
    # Aguardar instalação
    Start-Sleep -Seconds 5
    
    # Verificar se Ubuntu foi instalado
    Write-Host "🔍 Verificando instalação do Ubuntu..." -ForegroundColor Blue
    $ubuntuInstalled = wsl -l -v | Select-String "Ubuntu"
    if (-not $ubuntuInstalled) {
        Write-Host "❌ ERRO: Ubuntu não foi instalado corretamente" -ForegroundColor Red
        Write-Host "💡 Tente executar manualmente: wsl --install -d Ubuntu" -ForegroundColor Yellow
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    
    Write-Host "✅ Ubuntu instalado e funcionando!" -ForegroundColor Green
}

# Função para configurar Ubuntu
function Setup-Ubuntu {
    Write-Host ""
    Write-Host "📝 Criando script de configuração..." -ForegroundColor Blue
    
    # Criar script de configuração
    $setupScript = @'
#!/bin/bash
# Script de configuração automática do Whisper Transcriber
set -e

echo "🎙️ Configurando Whisper Transcriber no Ubuntu..."
echo "⏳ Isso pode levar 5-10 minutos..."

# Atualizar sistema
echo "📦 Atualizando sistema..."
sudo apt update -y && sudo apt upgrade -y

# Instalar dependências
echo "🔧 Instalando dependências..."
sudo apt install -y curl git docker.io docker-compose

# Configurar Docker
echo "🐳 Configurando Docker..."
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Baixar projeto
echo "📥 Baixando Whisper Transcriber..."
cd ~
if [ -d "transcribe" ]; then
    rm -rf transcribe
fi
git clone https://github.com/malvesro/transcribe.git
cd transcribe

# Configurar projeto
echo "⚙️ Configurando projeto..."
mkdir -p transcriber_web_app/videos transcriber_web_app/results

# Criar arquivo de configuração
cat > .env << 'EOF'
MAX_FILE_SIZE_GB=15
FLASK_ENV=development
COMPOSE_PROJECT_NAME=transcribe
EOF

# Iniciar serviços
echo "🚀 Iniciando Whisper Transcriber..."
sudo docker-compose up --build -d

echo "✅ Instalação concluída!"
echo "🌐 Acesse: http://localhost:5000"
echo "📁 Coloque seus arquivos em: ~/transcribe/transcriber_web_app/videos/"

# Criar script de inicialização
cat > ~/start-whisper.sh << 'SCRIPT_EOF'
#!/bin/bash
cd ~/transcribe
sudo docker-compose up -d
echo "🎙️ Whisper Transcriber iniciado!"
echo "🌐 Acesse: http://localhost:5000"
SCRIPT_EOF
chmod +x ~/start-whisper.sh

# Criar script de parada
cat > ~/stop-whisper.sh << 'SCRIPT_EOF'
#!/bin/bash
cd ~/transcribe
sudo docker-compose down
echo "⏹️ Whisper Transcriber parado!"
SCRIPT_EOF
chmod +x ~/stop-whisper.sh

echo "📋 Comandos úteis criados:"
echo "   Iniciar: ./start-whisper.sh"
echo "   Parar:   ./stop-whisper.sh"
'@

    # Salvar script temporariamente
    $setupScript | Out-File -FilePath "setup-ubuntu.sh" -Encoding UTF8
    
    Write-Host "📋 Copiando configuração para Ubuntu..." -ForegroundColor Blue
    
    try {
        # Copiar script para WSL
        wsl -d Ubuntu -- mkdir -p /tmp 2>$null
        Get-Content "setup-ubuntu.sh" | wsl -d Ubuntu -- tee /tmp/setup-ubuntu.sh > $null
        
        Write-Host "🚀 Executando configuração no Ubuntu..." -ForegroundColor Blue
        Write-Host "⏳ Isso pode levar 10-15 minutos na primeira vez..." -ForegroundColor Yellow
        Write-Host ""
        
        # Executar configuração
        wsl -d Ubuntu -- chmod +x /tmp/setup-ubuntu.sh
        wsl -d Ubuntu -- /tmp/setup-ubuntu.sh
        
        if ($LASTEXITCODE -ne 0) {
            throw "Configuração falhou"
        }
        
        Write-Host "✅ Configuração concluída!" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "❌ ERRO durante a configuração!" -ForegroundColor Red
        Write-Host "💡 Tente executar manualmente:" -ForegroundColor Yellow
        Write-Host "   1. Abra Ubuntu do menu Iniciar" -ForegroundColor Yellow
        Write-Host "   2. Execute: bash /tmp/setup-ubuntu.sh" -ForegroundColor Yellow
        Read-Host "Pressione Enter para sair"
        exit 1
    }
    finally {
        # Limpar arquivo temporário
        Remove-Item "setup-ubuntu.sh" -ErrorAction SilentlyContinue
    }
}

# Função para mostrar resultado final
function Show-Success {
    Write-Host ""
    Write-Host "████████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host "                        ✅ INSTALAÇÃO CONCLUÍDA!" -ForegroundColor Cyan
    Write-Host "████████████████████████████████████████████████████████████████████████████" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "🎉 O Whisper Transcriber está funcionando!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🌐 ACESSE AGORA: http://localhost:5000" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "📁 Para adicionar arquivos:" -ForegroundColor Blue
    Write-Host "   1. Abra Ubuntu do menu Iniciar" -ForegroundColor Blue
    Write-Host "   2. Vá para: cd ~/transcribe/transcriber_web_app/videos/" -ForegroundColor Blue
    Write-Host "   3. Copie seus arquivos de áudio/vídeo" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "🔧 Comandos úteis no Ubuntu:" -ForegroundColor Blue
    Write-Host "   ▶️  Iniciar:  ./start-whisper.sh" -ForegroundColor Blue
    Write-Host "   ⏹️  Parar:    ./stop-whisper.sh" -ForegroundColor Blue
    Write-Host ""
    
    Write-Host "💡 DICA: Adicione Ubuntu aos favoritos do menu Iniciar!" -ForegroundColor Yellow
    Write-Host ""
    
    # Tentar abrir o navegador
    Write-Host "🚀 Abrindo navegador..." -ForegroundColor Blue
    Start-Sleep -Seconds 3
    try {
        Start-Process "http://localhost:5000"
    }
    catch {
        Write-Host "💡 Abra manualmente: http://localhost:5000" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Read-Host "Pressione Enter para sair"
}

# Função principal
function Main {
    Write-Header
    Test-WindowsVersion
    Enable-WSL2
    Install-Ubuntu
    Setup-Ubuntu
    Show-Success
}

# Executar função principal
Main