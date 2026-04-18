@echo off
cd /d "%~dp0"
echo Installing dependencies for RadioPlayerV3.
echo Requires Python 3.10 on Windows (pinned tgcalls 2.0.0 has no cp311+ wheels on PyPI).
echo.
py -3.10 -m pip install -r requirements.txt
if errorlevel 1 (
  echo.
  echo If py -3.10 failed, install Python 3.10 from python.org and retry.
  pause
  exit /b 1
)
echo.
echo Done. Run the bot with: run.bat   or   py -3.10 main.py
pause
