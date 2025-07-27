@echo off
echo.
echo =================================================
echo   📁 Abrindo a pasta de videos...
echo =================================================
echo.
echo    O Windows Explorer sera aberto na pasta correta
echo    dentro do ambiente Linux (WSL).
echo.
echo    Copie seus arquivos de audio e video para esta pasta.
echo.

wsl -d Ubuntu -- explorer.exe ~/transcribe/transcriber_web_app/videos

pause
