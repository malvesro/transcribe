@echo off
echo.
echo =================================================
echo   🚀 Iniciando o Whisper Transcriber...
echo =================================================
echo.
echo    Este script tentara detectar seu ambiente (Docker Desktop ou WSL)
echo    e iniciar a aplicacao.
echo.

docker info >nul 2>&1
if not errorlevel 1 (
    echo ✅ Docker Desktop detectado. Iniciando...
    docker compose up --build -d
) else (
    echo 🐧 WSL detectado. Iniciando...
    wsl -d Ubuntu -- bash -c "cd ~/transcribe && sudo docker-compose up --build -d"
)

echo.
echo -------------------------------------------------
echo   Para usar, abra seu navegador em:
echo   http://localhost:5000
echo -------------------------------------------------
echo.
pause
