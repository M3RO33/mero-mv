@echo off
chcp 65001 >nul
cd /d "%~dp0"
title MERO Portfolio Server
echo.
echo  ===============================================
echo   MERO 포트폴리오 사이트를 시작합니다!
echo   브라우저가 자동으로 열려요.
echo   이 창을 닫으면 사이트가 꺼지니 열어두세요!
echo  ===============================================
echo.
start "" "http://localhost:8420/"
py -m http.server 8420 2>nul || python -m http.server 8420 2>nul || npx -y serve -l 8420 .
