@echo off
echo.
echo =================================================
echo   🚀 Iniciando o Whisper Transcriber...
echo =================================================
echo.
echo    Isto pode levar alguns segundos. A aplicacao estara pronta
echo    quando voce vir a mensagem "✅ Whisper Transcriber iniciado com sucesso!"
echo.

wsl -d Ubuntu -- bash -c "cd ~/transcribe && ./start-whisper.sh"

echo.
echo -------------------------------------------------
echo   Para usar, abra seu navegador em:
echo   http://localhost:5000
echo -------------------------------------------------
echo.
pause
