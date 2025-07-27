@echo off
echo.
echo =================================================
echo   ⏹️ Parando o Whisper Transcriber...
echo =================================================
echo.

wsl -d Ubuntu -- bash -c "cd ~/transcribe && ./stop-whisper.sh"

echo.
echo -------------------------------------------------
echo   Aplicacao parada com sucesso.
echo -------------------------------------------------
echo.
pause
