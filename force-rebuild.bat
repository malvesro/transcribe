@echo off
chcp 65001 >nul

:: ============================================================================
:: Script para Forçar a Reconstrução Completa do Ambiente Docker
:: ============================================================================
:: Use este script se a aplicação não estiver se comportando como esperado,
:: especialmente após uma atualização do código.
:: ============================================================================

echo.
echo AVISO: Este script ira parar e remover os containers e forcar uma
echo reconstrucao completa das imagens.
echo.
set /p "choice=Tem certeza que deseja continuar (S/N)? "
if /i not "%choice%"=="S" (
    echo Operacao cancelada.
    goto :eof
)

:: Detectar qual comando 'docker compose' usar
docker compose version >nul 2>&1
if not errorlevel 1 (
    set "COMPOSE_CMD=docker compose"
) else (
    docker-compose --version >nul 2>&1
    if not errorlevel 1 (
        set "COMPOSE_CMD=docker-compose"
    ) else (
        echo ERRO: Nenhum comando 'docker compose' ou 'docker-compose' foi encontrado.
        goto :eof
    )
)

echo.
echo 1. Parando e removendo containers existentes...
%COMPOSE_CMD% down

echo.
echo 2. Removendo a imagem antiga do worker (se existir)...
docker rmi transcriber-worker:1.1 2>nul

echo.
echo 3. Forcando a reconstrucao completa sem cache...
%COMPOSE_CMD% build --no-cache

echo.
echo 4. Iniciando os novos servicos...
%COMPOSE_CMD% up -d

if not errorlevel 1 (
    echo.
    echo ================================================================
    echo  AMBIENTE RECONSTRUIDO E INICIADO COM SUCESSO!
    echo ================================================================
) else (
    echo.
    echo ================================================================
    echo  ERRO DURANTE O PROCESSO. Verifique as mensagens acima.
    echo ================================================================
)

echo.
pause
