@echo off
chcp 65001 >nul
rem ============================================================
rem  Oracle を完全に削除します（データもすべて消えます）。
rem  最初からやり直したいときに使います。
rem ============================================================

rem --- リポジトリのルート（このフォルダの1つ上）を求める ---
pushd "%~dp0.." & set "REPO=%CD%" & popd

echo.
echo ★注意: Oracle のデータをすべて削除します。
echo   これまでに作った表やデータは元に戻せません。
echo.
set /p ANSWER="本当に削除しますか？ 削除する場合は y を入力して Enter: "
if /i not "%ANSWER%"=="y" ( echo. & echo 中止しました。何も削除していません。 & echo. & pause & exit /b )

echo.
echo Oracle を削除しています...
echo.

rem --- リポジトリのルートを WSL パスへ変換（--cd 非依存で確実に cd する） ---
for /f "usebackq delims=" %%i in (`wsl -d Ubuntu-22.04 wslpath "%REPO%"`) do set "WREPO=%%i"

wsl -d Ubuntu-22.04 -- bash -c "cd '%WREPO%' && bash scripts/stop-oracle.sh --purge"

if errorlevel 1 (
echo.
echo ============================================================
echo  [失敗] エラーが発生しました。上のメッセージをご確認ください。
echo  解決しない場合は、この画面をそのまま講師にお見せください。
echo ============================================================
echo.
pause
exit /b 1
)

echo.
echo ============================================================
echo  削除しました。
echo  もう一度使うには「Oracle起動.bat」をダブルクリックしてください。
echo ============================================================
echo.
pause
