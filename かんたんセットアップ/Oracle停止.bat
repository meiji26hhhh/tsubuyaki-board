@echo off
chcp 65001 >nul
set "WSL_UTF8=1"
rem ============================================================
rem  Oracle を停止します。
rem  作ったデータはそのまま残ります（次回また使えます）。
rem ============================================================

rem --- リポジトリのルート（このフォルダの1つ上）を求める ---
for %%I in ("%~dp0..") do set "REPO=%%~fI"

rem --- ログの保存先を用意 ---
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%t"
if not defined TS set "TS=latest"
set "LOGFILE=%LOGDIR%\oracle-stop_%TS%.log"

echo.
echo Oracle を停止しています...
echo.

rem --- リポジトリのルートを WSL パスへ変換（--cd 非依存で確実に cd する） ---
set "WREPO="
for /f "usebackq delims=" %%i in (`wsl -d Ubuntu-22.04 wslpath "%REPO%"`) do set "WREPO=%%i"
if not defined WREPO (
echo.
echo ============================================================
echo  [失敗] WSL の場所を特定できませんでした。
echo  WSL / Ubuntu-22.04 が正しく入っているか講師にご確認ください。
echo ============================================================
echo.
pause
exit /b 1
)

rem --- 実行（技術的な出力はすべてログファイルへ） ---
wsl -d Ubuntu-22.04 -- bash -c "cd '%WREPO%' && bash scripts/stop-oracle.sh" > "%LOGFILE%" 2>&1

if errorlevel 1 (
echo.
echo ============================================================
echo  [失敗] Oracle を停止できませんでした。
echo  詳しい記録は次のファイルに保存されています:
echo    %LOGFILE%
echo  解決しない場合は、このファイルを講師にお見せください。
echo ============================================================
echo.
pause
exit /b 1
)

echo.
echo ============================================================
echo  停止しました。データはそのまま残っています。
echo  （技術的な記録は %LOGFILE% に保存しました）
echo ============================================================
echo.
pause
