@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================================
:: 🎙️ Whisper Transcriber - Instalador Inteligente para Windows
:: ============================================================================
:: VERSÃO: 3.2 - Corrigida e Final
::
:: FUNCIONALIDADES:
:: - Lida com usuários Admin e Não-Admin.
:: - Se Admin: Instala tudo (WSL, Docker, etc.).
:: - Se Não-Admin: Verifica o ambiente e guia o usuário.
:: - Detecta e usa Docker Desktop se disponível.
:: - Cria atalhos `.bat` para facilitar o uso.
:: ============================================================================

:: --- Configurações ---
set "PROJECT_NAME=Whisper Transcriber"
set "REPO_URL=https://github.com/malvesro/transcribe.git"
set "LOG_FILE=%~dp0install.log"
set "IS_ADMIN=0"

:: --- Limpa o log antigo ---
del "%LOG_FILE%" >nul 2>&1
call :log_info "Iniciando %PROJECT_NAME% Instalador v3.2"

:: ============================================================================
:: LÓGICA PRINCIPAL
:: ============================================================================

:main
    call :display_header
    echo.
    echo Bem-vindo ao instalador do %PROJECT_NAME%!
    echo.

    :: Verificar se está executando como administrador
    net session >nul 2>&1
    if not errorlevel 1 set "IS_ADMIN=1"

    if %IS_ADMIN% equ 1 (
        echo ✅ Voce esta executando como Administrador. O script podera instalar
        echo    componentes do sistema, se necessario.
        echo.
        pause
        call :admin_flow
    ) else (
        echo ⚠️  Voce NAO esta executando como Administrador.
        echo.
        echo    O script tentara usar uma instalacao existente do Docker ou WSL,
        echo    mas nao podera instalar ou corrigir componentes do sistema.
        echo.
        pause
        call :non_admin_flow
    )

    if errorlevel 1 (
        goto :end_error
    ) else (
        goto :end_success
    )

:: ============================================================================
:: FLUXO PARA ADMINISTRADORES
:: ============================================================================

:admin_flow
    call :log_info "Iniciando fluxo de Administrador"

    :: 1. Verificar se o projeto já existe
    if exist "docker-compose.yml" (
        echo ✅ Projeto ja existe. Tentando atualizar e reiniciar...
        call :update_existing
        exit /b 0
    )

    :: 2. Tentar baixar o projeto primeiro
    if not exist "transcribe" (
        echo 📥 Baixando projeto do GitHub...
        git clone %REPO_URL% transcribe >nul 2>&1
        if errorlevel 1 (
            call :log_error "Falha ao clonar o repositorio. Git nao instalado ou problema de rede."
            echo ❌ ERRO: Falha ao baixar o projeto. Verifique se o Git esta instalado.
            exit /b 1
        )
    )
    cd transcribe

    :: 3. Detectar método de instalação
    docker info >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Docker Desktop detectado. Prosseguindo com a configuracao...
        call :setup_project
        exit /b %errorlevel%
    )

    echo ⚠️  Docker Desktop nao detectado. Tentando configurar o ambiente com WSL2...
    echo    Isto e mais complexo e pode exigir reinicializacoes.
    pause

    call :setup_wsl_and_docker
    if errorlevel 1 exit /b 1

    call :setup_project
    exit /b %errorlevel%

:: ============================================================================
:: FLUXO PARA NÃO-ADMINISTRADORES
:: ============================================================================

:non_admin_flow
    call :log_info "Iniciando fluxo de Nao-Administrador"

    :: 1. Verificar se o projeto já existe
    if not exist "docker-compose.yml" (
        echo ❌ ERRO: O projeto ainda nao foi baixado.
        echo    Peca a um administrador para executar este script primeiro para
        echo    baixar e configurar o projeto.
        exit /b 1
    )

    :: 2. Verificar se o ambiente está pronto
    docker info >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Docker Desktop esta pronto.
        call :setup_project
        exit /b %errorlevel%
    )

    wsl -d Ubuntu -- docker info >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Docker no WSL esta pronto.
        call :setup_project
        exit /b %errorlevel%
    )

    call :log_error "Ambiente Docker nao funcional para usuario nao-admin."
    echo ❌ ERRO: Nao foi encontrado um ambiente Docker funcional.
    echo    Peca ao seu administrador de TI para instalar e configurar o
    echo    Docker Desktop ou o WSL com Docker e garantir que seu usuario
    echo    tenha permissao para usa-lo.
    exit /b 1

:: ============================================================================
:: SUB-ROTINAS DE CONFIGURAÇÃO
:: ============================================================================

:setup_wsl_and_docker
    call :log_info "Iniciando setup do WSL e Docker"
    echo.
    echo --- CONFIGURANDO AMBIENTE WSL E DOCKER ---

    :: Verificar virtualização
    systeminfo | find "Hyper-V" | find "Sim" >nul
    if errorlevel 1 (
        call :log_error "Virtualizacao (Hyper-V) nao esta habilitada."
        echo ❌ ERRO: A virtualizacao de hardware (Hyper-V) nao esta ativada na BIOS/UEFI.
        echo    Ative-a na BIOS e tente novamente.
        exit /b 1
    )
    echo ✅ Virtualizacao ativada.

    :: Instalar WSL
    wsl --status >nul 2>&1
    if errorlevel 1 (
        echo 📦 Instalando WSL2...
        wsl --install -d Ubuntu --no-launch
        if errorlevel 1 (
            call :log_error "Falha ao instalar WSL/Ubuntu."
            echo ❌ ERRO: Falha ao instalar o WSL/Ubuntu.
            exit /b 1
        )
        echo.
        echo ❗ ACAO NECESSARIA - CRIE SEU USUARIO LINUX ❗
        echo    Uma janela do Ubuntu ira abrir. Crie seu usuario e senha nela.
        echo    Apos criar, feche a janela do Ubuntu e pressione uma tecla aqui.
        pause
        start "Ubuntu Setup" wsl -d Ubuntu
    )

    :: Instalar Docker no WSL
    wsl -d Ubuntu -- docker --version >nul 2>&1
    if errorlevel 1 (
        echo 📦 Instalando Docker dentro do Ubuntu...
        wsl -d Ubuntu -- bash -c "sudo apt-get update && sudo apt-get install -y docker.io docker-compose"
        wsl -d Ubuntu -- bash -c "sudo usermod -aG docker $USER"
    )

    echo ✅ Ambiente WSL e Docker configurado.
    goto :eof

:update_existing
    call :log_info "Atualizando projeto existente"
    if exist ".git" (
        echo 📥 Atualizando codigo via git...
        git pull
    )
    echo 🚀 Reiniciando a aplicacao com as novas alteracoes...
    call :setup_project
    goto :eof

:setup_project
    call :log_info "Configurando o projeto (diretorios, .env, atalhos)"
    echo.
    echo --- CONFIGURANDO PROJETO ---

    :: Criar diretórios e .env
    mkdir "transcriber_web_app\videos" 2>nul
    mkdir "transcriber_web_app\results" 2>nul

    :: Ajustar permissoes para WSL/Docker
    echo. 
    echo --- AJUSTANDO PERMISSOES DOS DIRETORIOS DE DADOS ---
    echo. 
    :: O UID/GID 1000 e o padrao para o appuser dentro do container.
    :: O caminho precisa ser mapeado para o WSL (ex: /mnt/c/path/to/project)
    set "PROJECT_PATH_WSL=/mnt/c%CD:C:=%"
    set "VIDEOS_PATH_WSL=%PROJECT_PATH_WSL%\transcriber_web_app\videos"
    set "RESULTS_PATH_WSL=%PROJECT_PATH_WSL%\transcriber_web_app\results"

    echo Executando chown/chmod via WSL para %VIDEOS_PATH_WSL% e %RESULTS_PATH_WSL%...
    wsl -d Ubuntu -- bash -c "sudo chown -R 1000:1000 '%VIDEOS_PATH_WSL%'"
    wsl -d Ubuntu -- bash -c "sudo chown -R 1000:1000 '%RESULTS_PATH_WSL%'"
    wsl -d Ubuntu -- bash -c "sudo chmod -R a+rx '%VIDEOS_PATH_WSL%'"
    wsl -d Ubuntu -- bash -c "sudo chmod -R a+rx '%RESULTS_PATH_WSL%'"
    if errorlevel 1 (
        echo ❌ ERRO: Falha ao ajustar permissoes via WSL.
        call :log_error "Falha ao ajustar permissoes via WSL."
        exit /b 1
    )
    echo ✅ Permissoes ajustadas.

    if not exist ".env" (
        echo MAX_FILE_SIZE_GB=15 > .env
        echo FLASK_ENV=development >> .env
        echo COMPOSE_PROJECT_NAME=transcribe >> .env
    )

    :: Criar atalhos
    call :create_shortcut_scripts

    :: Iniciar serviços
    echo 🚀 Iniciando a aplicacao...
    call start.bat
    goto :eof

:create_shortcut_scripts
    call :log_info "Criando scripts de atalho"

    :: Detectar se a instalação foi via WSL ou Docker Desktop
    docker info >nul 2>&1
    if not errorlevel 1 ( set "DOCKER_TYPE=desktop" ) else ( set "DOCKER_TYPE=wsl" )

    if "%DOCKER_TYPE%"=="wsl" (
        (
            echo @echo off
            echo wsl -d Ubuntu -- bash -c "cd ~/transcribe && sudo docker-compose up --build -d"
        ) > "start.bat"
        (
            echo @echo off
            echo wsl -d Ubuntu -- bash -c "cd ~/transcribe && sudo docker-compose down"
        ) > "stop.bat"
        (
            echo @echo off
            echo wsl -d Ubuntu -- explorer.exe ~/transcribe/transcriber_web_app/videos
        ) > "open-files-folder.bat"
    ) else (
        (
            echo @echo off
            echo docker compose up --build -d
        ) > "start.bat"
        (
            echo @echo off
            echo docker compose down
        ) > "stop.bat"
        (
            echo @echo off
            echo explorer.exe .\\transcriber_web_app\\videos
        ) > "open-files-folder.bat"
    )
    goto :eof

:: ============================================================================
:: TELAS DE SAÍDA
:: ============================================================================

:end_success
    call :log_info "Instalacao/configuracao concluida com sucesso."
    call :display_header
    echo.
    echo ✅ CONCLUIDO COM SUCESSO!
    echo.
    echo Para gerenciar a aplicacao, use os scripts .bat criados nesta pasta.
    echo.
    goto :end

:end_error
    call :log_error "A instalacao falhou."
    echo.
    echo ❌ A INSTALACAO FALHOU.
    echo    Um log de erros foi salvo em: %LOG_FILE%
    goto :end

:end
    echo.
    pause
    exit /b

:display_header
    cls
    echo ████████████████████████████████████████████████████████████████████████
    echo                  🎙️ %PROJECT_NAME% - Instalador para Windows
    echo ████████████████████████████████████████████████████████████████████████
    goto :eof

:log_info
    echo [%date% %time%] [INFO] %~1 >> "%LOG_FILE%"
    goto :eof

:log_error
    echo [%date% %time%] [ERROR] %~1 >> "%LOG_FILE%"
    goto :eof
