@echo off
chcp 65001 >nul
cd /d "%~dp0"
title MERO 사이트 배포
echo.
echo  수정한 내용을 사이트에 올립니다...
echo.
git pull --rebase
git add -A
git commit -m "update site"
git push
echo.
echo  ===============================================
echo   완료! 1~2분 뒤에 사이트에 반영돼요.
echo   https://m3ro33.github.io/mero-mv/
echo  ===============================================
echo.
pause
