@echo off
echo.
echo =================================================
echo   ⏹️ Parando o Whisper Transcriber...
echo =================================================
echo.

docker info >nul 2>&1
if not errorlevel 1 (
    echo ✅ Docker Desktop detectado. Parando...
    docker compose down
) else (
    echo 🐧 WSL detectado. Parando...
    wsl -d Ubuntu -- bash -c "cd ~/transcribe && sudo docker-compose down"
)

echo.
echo -------------------------------------------------
echo   Aplicacao parada com sucesso.
echo -------------------------------------------------
echo.
pause
