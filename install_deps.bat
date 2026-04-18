@echo off
cd /d "%~dp0"
echo Installing dependencies for RadioPlayerV3.
echo Requires Python 3.10 or 3.11 on Windows (tgcalls has no wheels for Python 3.12).
echo.
py -3.10 -m pip install -r requirements.txt
if errorlevel 1 (
  echo.
  echo If py -3.10 failed, try: py -3.11 -m pip install -r requirements.txt
  pause
  exit /b 1
)
echo.
echo Done. Run the bot with: run.bat   or   py -3.10 main.py
pause
