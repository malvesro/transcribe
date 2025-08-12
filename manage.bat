@echo off
rem manage.bat - Script unificado para gerenciar a aplicação Transcriber
rem Uso: manage.bat [start|stop|restart|rebuild|logs]

setlocal

rem Função para exibir ajuda
:show_help
echo Uso: %~n0 [start^|stop^|restart^|rebuild^|logs^|logs-web^|logs-worker]
echo Comandos:
echo   start         - Inicia a aplicacao em background.
echo   stop          - Para a aplicacao.
echo   restart       - Reinicia a aplicacao.
echo   rebuild       - Forca a reconstrucao das imagens Docker e inicia.
echo   logs          - Mostra os logs de todos os servicos.
echo   logs-web      - Mostra os logs apenas da webapp.
echo   logs-worker   - Mostra os logs apenas do whisper_worker.
echo.
echo Primeira vez? Rode 'manage.bat rebuild' para construir tudo.
goto:eof

rem Verifica se o Docker está instalado
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Erro: Docker nao encontrado. Por favor, instale o Docker Desktop e tente novamente.
    pause
    exit /b 1
)

rem Verifica se o Docker Compose está disponível
docker compose version >nul 2>&1
if %errorlevel% neq 0 (
    echo Erro: Docker Compose nao encontrado. Verifique sua instalacao do Docker Desktop.
    pause
    exit /b 1
)
set DC=docker compose

rem Verifica se o arquivo .env existe, se não, copia do exemplo
if not exist .env (
    echo Arquivo .env nao encontrado. Copiando de .env.example...
    copy .env.example .env
)

rem Navega para o diretório do script
cd /d "%~dp0"

rem Ação baseada no primeiro argumento
if "%1"=="start" goto:start
if "%1"=="stop" goto:stop
if "%1"=="restart" goto:restart
if "%1"=="rebuild" goto:rebuild
if "%1"=="logs" goto:logs
if "%1"=="logs-web" goto:logs_web
if "%1"=="logs-worker" goto:logs_worker
goto:show_help

:start
echo Iniciando a aplicacao Transcriber...
%DC% up -d
echo Aplicacao iniciada. Acesse em http://localhost:5000
goto:eof

:stop
echo Parando a aplicacao Transcriber...
%DC% down
echo Aplicacao parada.
goto:eof

:restart
echo Reiniciando a aplicacao Transcriber...
%DC% restart
echo Aplicacao reiniciada.
goto:eof

:rebuild
echo Forcando a reconstrucao da aplicacao...
set "TARGET_SERVICE=%2"
set "ACTUAL_SERVICE_NAME="

if "%TARGET_SERVICE%"=="" (
    echo Reconstruindo todos os servicos...
    %DC% down
    if %errorlevel% neq 0 (
        echo Erro: Falha ao parar a aplicacao. Verifique os logs acima para mais detalhes.
        exit /b 1
    )
    %DC% build --no-cache
    if %errorlevel% neq 0 (
        echo Erro: Falha ao construir a aplicacao. Verifique os logs acima para mais detalhes.
        exit /b 1
    )
    %DC% up -d
    if %errorlevel% neq 0 (
        echo Erro: Falha ao iniciar a aplicacao. Verifique os logs acima para mais detalhes.
        exit /b 1
    )
) else (
    if /i "%TARGET_SERVICE%"=="webapp" (
        set "ACTUAL_SERVICE_NAME=webapp"
    ) else if /i "%TARGET_SERVICE%"=="worker" (
        set "ACTUAL_SERVICE_NAME=whisper_worker"
    ) else (
        echo Erro: Servico invalido para reconstrucao. Use 'webapp' ou 'worker'.
        goto:show_help
    )

    echo Reconstruindo apenas o servico: %TARGET_SERVICE%...
    %DC% stop %ACTUAL_SERVICE_NAME%
    if %errorlevel% neq 0 (
        echo Erro: Falha ao parar o servico. Verifique os logs acima para mais detalhes.
        exit /b 1
    )
    %DC% build --no-cache %ACTUAL_SERVICE_NAME%
    if %errorlevel% neq 0 (
        echo Erro: Falha ao construir o servico. Verifique os logs acima para mais detalhes.
        exit /b 1
    )
    %DC% up -d %ACTUAL_SERVICE_NAME%
    if %errorlevel% neq 0 (
        echo Erro: Falha ao iniciar o servico. Verifique os logs acima para mais detalhes.
        exit /b 1
    )
)
echo.
echo 🎉 Reconstrucao completa e aplicacao iniciada com sucesso!
echo 👉 Acesse a interface web em: http://localhost:5000
echo.
goto:eof

:logs
echo Mostrando logs... (Pressione Ctrl+C para sair)
%DC% logs -f
goto:eof

:logs_web
echo Mostrando logs da webapp... (Pressione Ctrl+C para sair)
%DC% logs -f webapp
goto:eof

:logs_worker
echo Mostrando logs do whisper_worker... (Pressione Ctrl+C para sair)
%DC% logs -f whisper_worker
goto:eof
