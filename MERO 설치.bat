@echo off
chcp 65001 >nul
cd /d "%~dp0"
title MERO 포폴 업데이터 설치
if exist "%~dp0install.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
) else (
  echo   설치 파일을 인터넷에서 받아옵니다...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/M3RO33/mero-mv/main/install.ps1 | iex"
)
echo.
pause
