@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================================
:: 🎙️ Whisper Transcriber - Instalador Inteligente para Windows
:: ============================================================================
:: VERSÃO: 3.4 - Sem dependência do Git
:: ============================================================================

:: --- Configurações ---
set "PROJECT_NAME=Whisper Transcriber"
set "LOG_FILE=%~dp0install.log"
set "IS_ADMIN=0"

:: --- Limpa o log antigo ---
del "%LOG_FILE%" >nul 2>&1
call :log_info "Iniciando %PROJECT_NAME% Instalador v3.4"

:: ============================================================================
:: LÓGICA PRINCIPAL
:: ============================================================================

:main
    call :display_header
    echo.
    echo Bem-vindo ao instalador do %PROJECT_NAME%!
    echo.
    echo Este script deve ser executado da pasta extraida do ZIP baixado.

    net session >nul 2>&1
    if not errorlevel 1 set "IS_ADMIN=1"

    if %IS_ADMIN% equ 1 (
        echo ✅ Voce esta executando como Administrador.
        pause
        call :admin_flow
    ) else (
        echo ⚠️  Voce NAO esta executando como Administrador.
        pause
        call :non_admin_flow
    )

    if errorlevel 1 (
        goto :end_error
    ) else (
        goto :end_success
    )

:: ============================================================================
:: FLUXOS PRINCIPAIS
:: ============================================================================

:admin_flow
    call :log_info "Iniciando fluxo de Administrador"

    if not exist "docker-compose.yml" (
        call :log_error "Arquivo 'docker-compose.yml' nao encontrado."
        echo ❌ ERRO: Execute este script de dentro da pasta do projeto.
        exit /b 1
    )

    docker info >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Docker Desktop detectado.
        call :setup_project
        exit /b %errorlevel%
    )

    echo ⚠️  Docker Desktop nao detectado. Configurando com WSL2...
    pause

    call :setup_wsl_and_docker
    if errorlevel 1 exit /b 1

    call :setup_project
    exit /b %errorlevel%

:non_admin_flow
    call :log_info "Iniciando fluxo de Nao-Administrador"

    if not exist "docker-compose.yml" (
        echo ❌ ERRO: Execute este script de dentro da pasta do projeto.
        exit /b 1
    )

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
    echo ❌ ERRO: Ambiente Docker nao funcional.
    echo    Peca ao seu administrador de TI para configurar o Docker.
    exit /b 1

:: ============================================================================
:: SUB-ROTINAS
:: ============================================================================

:setup_wsl_and_docker
    call :log_info "Iniciando setup do WSL e Docker"
    echo.
    echo --- CONFIGURANDO AMBIENTE WSL E DOCKER ---

    :: Verificação de virtualização robusta
    echo Verificando se a virtualizacao esta ativada...
    systeminfo | find "Hipervisor detectado" >nul
    if errorlevel 1 (
        call :log_error "Virtualizacao nao detectada."
        echo ❌ ERRO: A virtualizacao de hardware nao esta ativada na sua maquina.
        echo    Por favor, ative-a na BIOS/UEFI e tente novamente.
        exit /b 1
    )
    echo ✅ Virtualizacao ativada.

    :: Verifica se QUALQUER distribuição Ubuntu já existe para QUALQUER usuário
    wsl --list | findstr "Ubuntu" >nul
    if not errorlevel 1 (
        echo ✅ Uma distribuicao Ubuntu ja foi encontrada no sistema.
        goto :install_docker_in_wsl
    )

    :: Se nenhuma foi encontrada, prossegue com a instalação
    echo 📦 Nenhuma distribuicao Ubuntu encontrada. Instalando WSL2 e Ubuntu...
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
    
    :: Loop de espera para garantir que a distro esteja pronta
    echo ⏳ Verificando se a distribuicao esta pronta...
    set "retries=0"
    :wait_for_distro_ready
    if %retries% geq 15 (
        echo ❌ ERRO: A distribuicao Ubuntu nao parece estar respondendo.
        exit /b 1
    )
    wsl -d Ubuntu -- exec /bin/true >nul 2>&1
    if not errorlevel 1 (
        echo ✅ Distribuicao Ubuntu pronta.
        goto :install_docker_in_wsl
    )
    timeout /t 10 /nobreak >nul
    set /a retries+=1
    goto :wait_for_distro_ready

:install_docker_in_wsl
    :: Instalar Docker no WSL se não estiver presente
    wsl -d Ubuntu -- docker --version >nul 2>&1
    if errorlevel 1 (
        echo 📦 Instalando Docker dentro do Ubuntu...
        wsl -d Ubuntu -- bash -c "sudo apt-get update && sudo apt-get install -y docker.io docker-compose"
        wsl -d Ubuntu -- bash -c "sudo usermod -aG docker $USER"
    )

    echo ✅ Ambiente WSL e Docker configurado.
    goto :eof

:setup_project
    call :log_info "Configurando projeto"
    mkdir "transcriber_web_app\videos" 2>nul
    mkdir "transcriber_web_app\results" 2>nul
    if not exist ".env" (
        (
            echo MAX_FILE_SIZE_GB=15
            echo FLASK_ENV=development
            echo COMPOSE_PROJECT_NAME=transcribe
        ) > ".env"
    )
    call :create_shortcut_scripts
    echo 🚀 Iniciando a aplicacao...
    call start.bat
    goto :eof

:create_shortcut_scripts
    call :log_info "Criando atalhos"
    docker info >nul 2>&1
    if not errorlevel 1 (
        set "DOCKER_TYPE=desktop"
        goto :create_desktop_shortcuts
    )
    set "DOCKER_TYPE=wsl"
    goto :create_wsl_shortcuts

:create_desktop_shortcuts
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
    goto :eof

:create_wsl_shortcuts
    call :log_info "Criando atalhos para WSL"
    
    set "WSL_PATH_CMD=wsl wslpath '%CD%'"
    for /f "delims=" %%a in ('%WSL_PATH_CMD%') do set "LINUX_PATH=%%a"

    (
        echo @echo off
        echo wsl -- bash -c "cd ""%LINUX_PATH%"" && sudo docker-compose up --build -d"
    ) > "start.bat"

    (
        echo @echo off
        echo wsl -- bash -c "cd ""%LINUX_PATH%"" && sudo docker-compose down"
    ) > "stop.bat"

    (
        echo @echo off
        echo wsl -- explorer.exe "%LINUX_PATH%/transcriber_web_app/videos"
    ) > "open-files-folder.bat"
    
    echo ✅ Scripts de atalho para WSL criados.
    goto :eof

:: ============================================================================
:: SAÍDA
:: ============================================================================

:end_success
    call :log_info "Instalacao concluida."
    echo.
    echo ✅ CONCLUIDO COM SUCESSO!
    goto :end

:end_error
    call :log_error "Instalacao falhou."
    echo.
    echo ❌ A INSTALACAO FALHOU.
    echo    Log salvo em: %LOG_FILE%
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
