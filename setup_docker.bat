@echo off
cd /d "%~dp0"
echo RadioPlayerV3 Docker setup (interactive .env + optional deploy)
echo Requires: Docker Desktop; Python 3.10 with pip install -r requirements.txt for session generation
echo.
py -3.10 setup_docker.py
if errorlevel 1 python setup_docker.py
if errorlevel 1 pause
