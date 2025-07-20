@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================================
:: 🎙️ Whisper Transcriber - Instalador Inteligente para Windows
:: ============================================================================
:: Este script detecta automaticamente a melhor forma de instalar:
:: - Se Docker Desktop já existe: usa ele
:: - Se não existe: instala WSL2 + Ubuntu + Docker nativo (mais leve)
:: ============================================================================

echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                🎙️ Whisper Transcriber - Instalador para Windows
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo ✨ Este instalador escolherá automaticamente a melhor opção para você!
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

:: Verificar se o projeto já existe
echo 🔍 Verificando se o projeto já existe...
if exist "transcriber_web_app" (
    echo ✅ Projeto já existe!
    goto :update_existing
)

:: Detectar qual método usar
echo 🔍 Detectando melhor método de instalação...
echo.

:: Verificar se Docker Desktop está instalado e funcionando
docker info >nul 2>&1
if not errorlevel 1 (
    echo ✅ Docker Desktop encontrado e funcionando!
    echo 🎯 Usando Docker Desktop (método simples)
    goto :install_with_docker_desktop
)

:: Verificar se Docker Desktop está instalado mas não rodando
docker --version >nul 2>&1
if not errorlevel 1 (
    echo ⚠️  Docker Desktop instalado mas não está rodando
    echo.
    echo 🚀 Por favor:
    echo    1. Abra o Docker Desktop
    echo    2. Aguarde ele inicializar completamente
    echo    3. Execute este script novamente
    echo.
    pause
    exit /b 1
)

:: Docker Desktop não encontrado, usar WSL2
echo 📦 Docker Desktop não encontrado
echo 🎯 Usando WSL2 + Ubuntu + Docker nativo (método leve)
echo.
echo 🔧 O que será instalado:
echo    • WSL2 (Subsistema Linux para Windows)
echo    • Ubuntu (sistema Linux leve)
echo    • Docker nativo (dentro do Ubuntu)
echo    • Whisper Transcriber
echo.
goto :install_with_wsl

:: ============================================================================
:: ATUALIZAÇÃO DE PROJETO EXISTENTE
:: ============================================================================
:update_existing
echo 🔄 Atualizando projeto existente...

:: Detectar se está usando WSL ou Docker Desktop
wsl -d Ubuntu -- test -d ~/transcribe >nul 2>&1
if not errorlevel 1 (
    echo 🐧 Detectado: instalação via WSL2
    echo 🔄 Atualizando via WSL2...
    wsl -d Ubuntu -- bash -c "cd ~/transcribe && git pull && docker compose up --build -d"
) else (
    echo 🐳 Detectado: instalação via Docker Desktop
    echo 🔄 Atualizando via Docker Desktop...
    
    :: Verificar se Docker está funcionando
    docker info >nul 2>&1
    if errorlevel 1 (
        echo ❌ ERRO: Docker Desktop não está rodando!
        echo 🚀 Por favor, abra o Docker Desktop e tente novamente
        pause
        exit /b 1
    )
    
    :: Atualizar via git se possível
    git pull >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Código atualizado via git!
    ) else (
        echo ⚠️  Não foi possível atualizar via git, continuando...
    )
    
    :: Reiniciar serviços
    echo 🔄 Reiniciando serviços...
    docker compose down >nul 2>&1
    docker compose up --build -d
)

goto :success

:: ============================================================================
:: INSTALAÇÃO COM DOCKER DESKTOP
:: ============================================================================
:install_with_docker_desktop
echo.
echo 🐳 Instalando com Docker Desktop...

:: Verificar Docker Compose
docker compose version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Docker Compose v2 não encontrado, tentando v1...
    docker-compose --version >nul 2>&1
    if errorlevel 1 (
        echo ❌ ERRO: Docker Compose não encontrado!
        echo 📥 Por favor, atualize o Docker Desktop para a versão mais recente
        pause
        exit /b 1
    ) else (
        set COMPOSE_CMD=docker-compose
        echo ✅ Docker Compose v1 encontrado!
    )
) else (
    set COMPOSE_CMD=docker compose
    echo ✅ Docker Compose v2 encontrado!
)

:: Baixar projeto
echo 📥 Baixando projeto...
echo ⏳ Isso pode levar alguns minutos dependendo da sua conexão...
git clone https://github.com/malvesro/transcribe.git
if errorlevel 1 (
    echo ❌ ERRO: Falha ao baixar projeto
    echo 💡 Verifique sua conexão com a internet
    pause
    exit /b 1
)
echo ✅ Projeto baixado com sucesso!

cd transcribe

:: Criar diretórios
echo 📁 Criando diretórios...
if not exist "transcriber_web_app\videos" mkdir "transcriber_web_app\videos"
if not exist "transcriber_web_app\results" mkdir "transcriber_web_app\results"

:: Configurar ambiente
echo ⚙️ Configurando ambiente...
if not exist ".env" (
    echo MAX_FILE_SIZE_GB=15 > .env
    echo FLASK_ENV=development >> .env
    echo COMPOSE_PROJECT_NAME=transcribe >> .env
)

:: Iniciar serviços
echo 🚀 Iniciando serviços...
echo ⏳ Baixando imagens Docker e construindo containers...
echo 💡 Isso pode levar 5-15 minutos na primeira vez
echo.
echo 📊 Progresso:
echo    [1/3] 📥 Baixando imagens base...
%COMPOSE_CMD% pull >nul 2>&1
echo    [2/3] 🏗️  Construindo aplicação...
%COMPOSE_CMD% build >nul 2>&1
echo    [3/3] 🚀 Iniciando serviços...
%COMPOSE_CMD% up -d

if errorlevel 1 (
    echo ❌ ERRO: Falha ao iniciar serviços
    echo 💡 Tentando diagnóstico...
    %COMPOSE_CMD% logs
    pause
    exit /b 1
)

echo ✅ Serviços iniciados com sucesso!

goto :success

:: ============================================================================
:: INSTALAÇÃO COM WSL2
:: ============================================================================
:install_with_wsl
echo.
echo 🐧 Instalando com WSL2...

:: Verificar versão do Windows
echo 🔍 Verificando versão do Windows...
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
for /f "tokens=1 delims=." %%a in ("%VERSION%") do set MAJOR=%%a
for /f "tokens=2 delims=." %%a in ("%VERSION%") do set MINOR=%%a

if %MAJOR% LSS 10 (
    echo ❌ ERRO: Windows muito antigo!
    echo    Precisa do Windows 10 versão 2004 ou superior
    pause
    exit /b 1
)

if %MAJOR% EQU 10 if %MINOR% LSS 19041 (
    echo ❌ ERRO: Windows 10 muito antigo!
    echo    Precisa da versão 2004 (build 19041) ou superior
    pause
    exit /b 1
)

echo ✅ Versão do Windows compatível!

:: Verificar se WSL já está instalado
echo 🔍 Verificando WSL...
wsl --status >nul 2>&1
if not errorlevel 1 (
    echo ✅ WSL já instalado!
    goto :check_ubuntu
)

:: Instalar WSL
echo 📦 Instalando WSL2...
echo ⏳ Isso pode levar alguns minutos...
echo.
echo 📊 Progresso WSL2:
echo    [1/3] 🔧 Habilitando Subsistema Linux...
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart >nul
echo    [2/3] 🔧 Habilitando Plataforma de Máquina Virtual...
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart >nul
echo    [3/3] ⚙️ Configurando WSL2 como padrão...
wsl --set-default-version 2 >nul 2>&1
echo ✅ WSL2 configurado com sucesso!

:check_ubuntu
:: Verificar Ubuntu
echo 🔍 Verificando Ubuntu...
wsl -l -v | findstr Ubuntu >nul 2>&1
if not errorlevel 1 (
    echo ✅ Ubuntu já instalado!
    goto :check_docker_wsl
)

:: Instalar Ubuntu
echo 📦 Instalando Ubuntu...
echo ⏳ Baixando e instalando Ubuntu (pode levar 5-10 minutos)...
echo 💡 Aguarde, o processo está rodando em segundo plano...
wsl --install -d Ubuntu --no-launch
if errorlevel 1 (
    echo ❌ ERRO: Falha ao instalar Ubuntu
    echo 💡 Tente executar manualmente: wsl --install -d Ubuntu
    pause
    exit /b 1
)
echo ✅ Ubuntu instalado com sucesso!
timeout /t 5 /nobreak >nul

:check_docker_wsl
:: Verificar Docker no Ubuntu
echo 🔍 Verificando Docker no Ubuntu...
wsl -d Ubuntu -- docker --version >nul 2>&1
if not errorlevel 1 (
    echo ✅ Docker já instalado no Ubuntu!
    goto :install_project_wsl
)

:: Instalar Docker no Ubuntu
echo 📦 Instalando Docker no Ubuntu...
echo ⏳ Isso pode levar 5-10 minutos...
echo.
echo 📊 Progresso Docker:
echo    [1/5] 📦 Atualizando repositórios...
wsl -d Ubuntu -- bash -c "sudo apt update" >nul 2>&1
echo    [2/5] 📥 Baixando Docker...
wsl -d Ubuntu -- bash -c "sudo apt install -y docker.io" >nul 2>&1
echo    [3/5] 📥 Instalando Docker Compose...
wsl -d Ubuntu -- bash -c "sudo apt install -y docker-compose" >nul 2>&1
echo    [4/5] ⚙️ Configurando Docker...
wsl -d Ubuntu -- bash -c "sudo systemctl enable docker && sudo systemctl start docker" >nul 2>&1
echo    [5/5] 👤 Configurando usuário...
wsl -d Ubuntu -- bash -c "sudo usermod -aG docker \$USER" >nul 2>&1
echo ✅ Docker instalado e configurado com sucesso!

:install_project_wsl
:: Verificar se projeto já existe no Ubuntu
echo 🔍 Verificando projeto no Ubuntu...
wsl -d Ubuntu -- test -d ~/transcribe >nul 2>&1
if not errorlevel 1 (
    echo ✅ Projeto já existe! Atualizando...
    wsl -d Ubuntu -- bash -c "cd ~/transcribe && git pull && docker compose up --build -d"
    goto :success
)

:: Instalar projeto no Ubuntu
echo 📥 Instalando projeto no Ubuntu...
echo ⏳ Baixando código e configurando ambiente...
echo.
echo 📊 Progresso do projeto:
echo    [1/5] 📥 Baixando código fonte...
wsl -d Ubuntu -- bash -c "cd ~ && git clone https://github.com/malvesro/transcribe.git" >nul 2>&1
echo    [2/5] 📁 Criando diretórios...
wsl -d Ubuntu -- bash -c "cd ~/transcribe && mkdir -p transcriber_web_app/videos transcriber_web_app/results" >nul 2>&1
echo    [3/5] ⚙️ Configurando ambiente...
wsl -d Ubuntu -- bash -c "cd ~/transcribe && echo 'MAX_FILE_SIZE_GB=15' > .env && echo 'FLASK_ENV=development' >> .env && echo 'COMPOSE_PROJECT_NAME=transcribe' >> .env" >nul 2>&1
echo    [4/5] 🐳 Baixando imagens Docker...
wsl -d Ubuntu -- bash -c "cd ~/transcribe && docker compose pull" >nul 2>&1
echo    [5/5] 🚀 Iniciando serviços...
wsl -d Ubuntu -- bash -c "cd ~/transcribe && docker compose up --build -d" >nul 2>&1
echo ✅ Projeto instalado e iniciado com sucesso!

:: Criar scripts de conveniência
echo 📝 Criando scripts de conveniência...
wsl -d Ubuntu -- bash -c "cd ~/transcribe && cat > start-whisper.sh << 'EOF'
#!/bin/bash
cd ~/transcribe
echo '🎙️ Iniciando Whisper Transcriber...'
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD='docker compose'
else
    COMPOSE_CMD='docker-compose'
fi
sudo \$COMPOSE_CMD up -d
if [ \$? -eq 0 ]; then
    echo '✅ Whisper Transcriber iniciado com sucesso!'
    echo '🌐 Acesse: http://localhost:5000'
else
    echo '❌ Erro ao iniciar Whisper Transcriber'
    exit 1
fi
EOF"

wsl -d Ubuntu -- bash -c "cd ~/transcribe && cat > stop-whisper.sh << 'EOF'
#!/bin/bash
cd ~/transcribe
echo '⏹️ Parando Whisper Transcriber...'
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD='docker compose'
else
    COMPOSE_CMD='docker-compose'
fi
sudo \$COMPOSE_CMD down
if [ \$? -eq 0 ]; then
    echo '✅ Whisper Transcriber parado com sucesso!'
else
    echo '❌ Erro ao parar Whisper Transcriber'
    exit 1
fi
EOF"

wsl -d Ubuntu -- bash -c "cd ~/transcribe && cat > logs-whisper.sh << 'EOF'
#!/bin/bash
cd ~/transcribe
echo '📜 Mostrando logs do Whisper Transcriber...'
echo 'Pressione Ctrl+C para sair'
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD='docker compose'
else
    COMPOSE_CMD='docker-compose'
fi
sudo \$COMPOSE_CMD logs -f
EOF"

wsl -d Ubuntu -- bash -c "cd ~/transcribe && chmod +x start-whisper.sh stop-whisper.sh logs-whisper.sh" >nul 2>&1
echo ✅ Scripts de conveniência criados!

goto :success

:: ============================================================================
:: SUCESSO
:: ============================================================================
:success
echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                        ✅ INSTALAÇÃO CONCLUÍDA!
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo 🎉 O Whisper Transcriber está funcionando!
echo 🌐 ACESSE AGORA: http://localhost:5000
echo.

:: Detectar método usado para instruções específicas
wsl -d Ubuntu -- test -d ~/transcribe >nul 2>&1
if not errorlevel 1 (
    echo 📋 Instalação via WSL2 - Comandos úteis:
    echo    🚀 Iniciar: wsl -d Ubuntu -- bash ~/transcribe/start-whisper.sh
    echo    ⏹️  Parar:   wsl -d Ubuntu -- bash ~/transcribe/stop-whisper.sh
    echo    📜 Logs:    wsl -d Ubuntu -- bash ~/transcribe/logs-whisper.sh
    echo    📁 Arquivos: wsl -d Ubuntu -- explorer.exe ~/transcribe/transcriber_web_app/videos/
) else (
    echo 📋 Instalação via Docker Desktop - Comandos úteis:
    echo    🚀 Iniciar: docker compose up -d
    echo    ⏹️  Parar:   docker compose down
    echo    📜 Logs:    docker compose logs -f
    echo    📁 Arquivos: .\transcriber_web_app\videos\
)

echo.
echo 🚀 Abrindo navegador...
timeout /t 3 /nobreak >nul
start http://localhost:5000

echo.
echo Pressione qualquer tecla para sair...
pause >nul