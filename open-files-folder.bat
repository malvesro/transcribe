@echo off
echo.
echo =================================================
echo   📁 Abrindo a pasta de videos...
echo =================================================
echo.

docker info >nul 2>&1
if not errorlevel 1 (
    echo ✅ Docker Desktop detectado. Abrindo pasta local...
    explorer.exe .\\transcriber_web_app\\videos
) else (
    echo 🐧 WSL detectado. Abrindo pasta do Linux...
    wsl -d Ubuntu -- explorer.exe ~/transcribe/transcriber_web_app/videos
)

pause
