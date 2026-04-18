@echo off
cd /d "%~dp0"
echo RadioPlayerV3 .env wizard (any Python 3.x with pip install -r requirements.txt for pyrogram)
echo.
python setup_env.py
if errorlevel 1 pause
