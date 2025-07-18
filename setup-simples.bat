@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================================================
:: 🎙️ Whisper Transcriber - Instalação Simples para Windows
:: ============================================================================
:: Este script instala e configura o Whisper Transcriber de forma automática
:: Versão: 2.0 - Compatível com Docker Compose
:: ============================================================================

echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                    🎙️ Whisper Transcriber - Setup Simples
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo ✨ Este script irá configurar automaticamente o Whisper Transcriber
echo 📋 Requisitos: Docker Desktop instalado e funcionando
echo.

:: Verificar se Docker está instalado e funcionando
echo 🔍 Verificando Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ❌ ERRO: Docker não encontrado!
    echo.
    echo 📥 Por favor, instale o Docker Desktop primeiro:
    echo    👉 https://www.docker.com/products/docker-desktop/
    echo.
    echo 📋 Após instalar:
    echo    1. Reinicie o computador
    echo    2. Abra o Docker Desktop
    echo    3. Execute este script novamente
    echo.
    pause
    exit /b 1
)

echo ✅ Docker encontrado!

:: Verificar se Docker está rodando
echo 🔍 Verificando se Docker está rodando...
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo ❌ ERRO: Docker não está rodando!
    echo.
    echo 🚀 Por favor:
    echo    1. Abra o Docker Desktop
    echo    2. Aguarde ele inicializar completamente
    echo    3. Execute este script novamente
    echo.
    pause
    exit /b 1
)

echo ✅ Docker está funcionando!

:: Verificar se Docker Compose está disponível
echo 🔍 Verificando Docker Compose...
docker compose version >nul 2>&1
if errorlevel 1 (
    echo ⚠️  Docker Compose v2 não encontrado, tentando v1...
    docker-compose --version >nul 2>&1
    if errorlevel 1 (
        echo.
        echo ❌ ERRO: Docker Compose não encontrado!
        echo.
        echo 📥 Por favor, atualize o Docker Desktop para a versão mais recente
        echo    👉 https://www.docker.com/products/docker-desktop/
        echo.
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

:: Criar diretórios necessários
echo.
echo 📁 Criando diretórios necessários...
if not exist "transcriber_web_app\videos" mkdir "transcriber_web_app\videos"
if not exist "transcriber_web_app\results" mkdir "transcriber_web_app\results"
echo ✅ Diretórios criados!

:: Configurar limite de arquivo (opcional)
echo.
echo ⚙️ Configurando limite de arquivo...
if not exist ".env" (
    echo # Configurações do Whisper Transcriber > .env
    echo MAX_FILE_SIZE_GB=15 >> .env
    echo FLASK_ENV=development >> .env
    echo COMPOSE_PROJECT_NAME=transcribe >> .env
    echo ✅ Arquivo .env criado com limite de 15GB
) else (
    echo ✅ Arquivo .env já existe
)

:: Construir e iniciar os serviços
echo.
echo 🏗️ Construindo e iniciando os serviços...
echo ⏳ Isso pode levar alguns minutos na primeira vez...
echo.

%COMPOSE_CMD% up --build -d

if errorlevel 1 (
    echo.
    echo ❌ ERRO: Falha ao iniciar os serviços!
    echo.
    echo 🔧 Possíveis soluções:
    echo    1. Verifique se o Docker Desktop está funcionando
    echo    2. Reinicie o Docker Desktop
    echo    3. Execute: %COMPOSE_CMD% down
    echo    4. Tente novamente
    echo.
    pause
    exit /b 1
)

:: Aguardar serviços ficarem prontos
echo.
echo ⏳ Aguardando serviços ficarem prontos...
timeout /t 10 /nobreak >nul

:: Verificar se os serviços estão rodando
%COMPOSE_CMD% ps

echo.
echo ████████████████████████████████████████████████████████████████████████████
echo                           ✅ INSTALAÇÃO CONCLUÍDA!
echo ████████████████████████████████████████████████████████████████████████████
echo.
echo 🎉 O Whisper Transcriber está funcionando!
echo.
echo 🌐 Acesse: http://localhost:5000
echo.
echo 📁 Coloque seus arquivos de vídeo/áudio em:
echo    📂 transcriber_web_app\videos\
echo.
echo 📊 Limite atual de arquivo: 15GB
echo    💡 Para alterar: edite o arquivo .env
echo.
echo 🔧 Comandos úteis:
echo    ▶️  Iniciar:  %COMPOSE_CMD% up -d
echo    ⏹️  Parar:    %COMPOSE_CMD% down
echo    📋 Status:   %COMPOSE_CMD% ps
echo    📜 Logs:     %COMPOSE_CMD% logs -f
echo.
echo 🚀 Abrindo o navegador...
start http://localhost:5000

echo.
echo Pressione qualquer tecla para sair...
pause >nul