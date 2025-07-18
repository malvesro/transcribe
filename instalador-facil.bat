@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================================
:: 🎙️ Whisper Transcriber - Instalador Super Fácil para Windows
:: ============================================================================
:: Este script instala TUDO automaticamente usando WSL2 + Ubuntu
:: Não precisa do Docker Desktop - muito mais simples!
:: ============================================================================

echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                🎙️ Whisper Transcriber - Instalador Super Fácil
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo ✨ Este instalador fará TUDO automaticamente para você!
echo 📋 Não precisa instalar nada manualmente - deixe conosco!
echo.
echo 🔧 O que será instalado:
echo    • WSL2 (Subsistema Linux para Windows)
echo    • Ubuntu (sistema Linux leve)
echo    • Docker (dentro do Ubuntu)
echo    • Whisper Transcriber (nossa ferramenta)
echo.

:: Verificar se está executando como administrador
net session >nul 2>&1
if errorlevel 1 (
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
echo.

:: Verificar versão do Windows
echo 🔍 Verificando versão do Windows...
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
for /f "tokens=1 delims=." %%a in ("%VERSION%") do set MAJOR=%%a
for /f "tokens=2 delims=." %%a in ("%VERSION%") do set MINOR=%%a

if %MAJOR% LSS 10 (
    echo ❌ ERRO: Windows muito antigo!
    echo    Precisa do Windows 10 versão 2004 ou superior
    echo    Ou Windows 11 qualquer versão
    pause
    exit /b 1
)

if %MAJOR% EQU 10 if %MINOR% LSS 19041 (
    echo ❌ ERRO: Windows 10 muito antigo!
    echo    Precisa da versão 2004 ^(build 19041^) ou superior
    echo    💡 Atualize o Windows e tente novamente
    pause
    exit /b 1
)

echo ✅ Versão do Windows compatível!

:: Habilitar WSL2
echo.
echo 🔧 Habilitando WSL2...
echo ⏳ Isso pode levar alguns minutos...

dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

echo ✅ Recursos do WSL2 habilitados!

:: Definir WSL2 como padrão
echo.
echo 🔧 Configurando WSL2 como padrão...
wsl --set-default-version 2

:: Instalar Ubuntu
echo.
echo 🐧 Instalando Ubuntu...
echo ⏳ Isso pode levar alguns minutos...

wsl --install -d Ubuntu --no-launch

if errorlevel 1 (
    echo ⚠️  Tentando método alternativo...
    wsl --install Ubuntu --no-launch
)

echo ✅ Ubuntu instalado!

:: Aguardar um pouco
timeout /t 5 /nobreak >nul

:: Verificar se Ubuntu foi instalado
echo.
echo 🔍 Verificando instalação do Ubuntu...
wsl -l -v | findstr Ubuntu >nul
if errorlevel 1 (
    echo ❌ ERRO: Ubuntu não foi instalado corretamente
    echo 💡 Tente executar manualmente: wsl --install -d Ubuntu
    pause
    exit /b 1
)

echo ✅ Ubuntu instalado e funcionando!

:: Criar script de configuração para o Ubuntu
echo.
echo 📝 Criando script de configuração...

(
echo #!/bin/bash
echo # Script de configuração automática do Whisper Transcriber
echo set -e
echo.
echo echo "🎙️ Configurando Whisper Transcriber no Ubuntu..."
echo echo "⏳ Isso pode levar 5-10 minutos..."
echo.
echo # Atualizar sistema
echo echo "📦 Atualizando sistema..."
echo sudo apt update -y ^&^& sudo apt upgrade -y
echo.
echo # Instalar dependências
echo echo "🔧 Instalando dependências..."
echo sudo apt install -y curl git docker.io docker-compose
echo.
echo # Configurar Docker
echo echo "🐳 Configurando Docker..."
echo sudo systemctl enable docker
echo sudo systemctl start docker
echo sudo usermod -aG docker $USER
echo.
echo # Baixar projeto
echo echo "📥 Baixando Whisper Transcriber..."
echo cd ~
echo if [ -d "transcribe" ]; then
echo     rm -rf transcribe
echo fi
echo git clone https://github.com/malvesro/transcribe.git
echo cd transcribe
echo.
echo # Configurar projeto
echo echo "⚙️ Configurando projeto..."
echo mkdir -p transcriber_web_app/videos transcriber_web_app/results
echo.
echo # Criar arquivo de configuração
echo cat ^> .env ^<^< 'EOF'
echo MAX_FILE_SIZE_GB=15
echo FLASK_ENV=development
echo COMPOSE_PROJECT_NAME=transcribe
echo EOF
echo.
echo # Iniciar serviços
echo echo "🚀 Iniciando Whisper Transcriber..."
echo sudo docker-compose up --build -d
echo.
echo echo "✅ Instalação concluída!"
echo echo "🌐 Acesse: http://localhost:5000"
echo echo "📁 Coloque seus arquivos em: ~/transcribe/transcriber_web_app/videos/"
echo.
echo # Criar script de inicialização
echo cat ^> ~/start-whisper.sh ^<^< 'SCRIPT_EOF'
echo #!/bin/bash
echo cd ~/transcribe
echo sudo docker-compose up -d
echo echo "🎙️ Whisper Transcriber iniciado!"
echo echo "🌐 Acesse: http://localhost:5000"
echo SCRIPT_EOF
echo chmod +x ~/start-whisper.sh
echo.
echo # Criar script de parada
echo cat ^> ~/stop-whisper.sh ^<^< 'SCRIPT_EOF'
echo #!/bin/bash
echo cd ~/transcribe
echo sudo docker-compose down
echo echo "⏹️ Whisper Transcriber parado!"
echo SCRIPT_EOF
echo chmod +x ~/stop-whisper.sh
echo.
echo echo "📋 Comandos úteis criados:"
echo echo "   Iniciar: ./start-whisper.sh"
echo echo "   Parar:   ./stop-whisper.sh"
) > setup-ubuntu.sh

:: Copiar script para WSL
echo 📋 Copiando configuração para Ubuntu...
wsl -d Ubuntu -- mkdir -p /tmp
wsl -d Ubuntu -- cp /mnt/c/Users/%USERNAME%/setup-ubuntu.sh /tmp/ 2>nul || (
    echo ⚠️  Copiando de forma alternativa...
    type setup-ubuntu.sh | wsl -d Ubuntu -- tee /tmp/setup-ubuntu.sh > nul
)

:: Executar configuração no Ubuntu
echo.
echo 🚀 Executando configuração no Ubuntu...
echo ⏳ Isso pode levar 10-15 minutos na primeira vez...
echo.

wsl -d Ubuntu -- chmod +x /tmp/setup-ubuntu.sh
wsl -d Ubuntu -- /tmp/setup-ubuntu.sh

if errorlevel 1 (
    echo.
    echo ❌ ERRO durante a configuração!
    echo 💡 Tente executar manualmente:
    echo    1. Abra Ubuntu do menu Iniciar
    echo    2. Execute: bash /tmp/setup-ubuntu.sh
    pause
    exit /b 1
)

:: Limpar arquivo temporário
del setup-ubuntu.sh 2>nul

echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                        ✅ INSTALAÇÃO CONCLUÍDA!
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo 🎉 O Whisper Transcriber está funcionando!
echo.
echo 🌐 ACESSE AGORA: http://localhost:5000
echo.
echo 📁 Para adicionar arquivos:
echo    1. Abra Ubuntu do menu Iniciar
echo    2. Vá para: cd ~/transcribe/transcriber_web_app/videos/
echo    3. Copie seus arquivos de áudio/vídeo
echo.
echo 🔧 Comandos úteis no Ubuntu:
echo    ▶️  Iniciar:  ./start-whisper.sh
echo    ⏹️  Parar:    ./stop-whisper.sh
echo.
echo 💡 DICA: Adicione Ubuntu aos favoritos do menu Iniciar!
echo.

:: Tentar abrir o navegador
echo 🚀 Abrindo navegador...
timeout /t 3 /nobreak >nul
start http://localhost:5000

echo.
echo Pressione qualquer tecla para sair...
pause >nul