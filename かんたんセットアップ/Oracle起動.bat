@echo off
chcp 65001 >nul
set "WSL_UTF8=1"
rem ============================================================
rem  Oracle を起動します。
rem  初回は準備のため数分かかります（そのままお待ちください）。
rem ============================================================

rem --- リポジトリのルート（このフォルダの1つ上）を求める ---
for %%I in ("%~dp0..") do set "REPO=%%~fI"

rem --- ログの保存先を用意 ---
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%t"
if not defined TS set "TS=latest"
set "LOGFILE=%LOGDIR%\oracle-start_%TS%.log"

echo.
echo Oracle を起動しています。完了の表示が出るまでお待ちください...
echo （初回は数分かかります。進捗を画面に表示しながら logs フォルダにも記録します）
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

rem --- ログファイルの WSL パスを用意（WSL 内 tee 用） ---
set "WLOGFILE="
for /f "usebackq delims=" %%i in (`wsl -d Ubuntu-22.04 wslpath "%LOGFILE%"`) do set "WLOGFILE=%%i"
if not defined WLOGFILE (
echo.
echo ============================================================
echo  [失敗] ログ保存先のパス変換に失敗しました。
echo  WSL / Ubuntu-22.04 が正しく入っているか講師にご確認ください。
echo ============================================================
echo.
pause
exit /b 1
)

rem --- 実行（進捗を画面に出しつつログにも記録。終了コードを伝播） ---
wsl -d Ubuntu-22.04 -- bash -c "set -o pipefail; cd '%WREPO%' && bash scripts/start-oracle.sh 2>&1 | tee '%WLOGFILE%'"

if errorlevel 1 (
echo.
echo ============================================================
echo  [失敗] Oracle を起動できませんでした。
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
echo  Oracle の準備ができました（起動成功）。
echo  ↑「Oracle XE is ready.」と接続情報が画面に表示されています。
echo.
echo  接続情報（控え）:
echo    URL      : jdbc:oracle:thin:@//localhost:1521/XEPDB1
echo    User     : tsubuyaki
echo    Password : .env の ORACLE_APP_PWD（初期値 tsubuyaki_pw）
echo.
echo  （技術的な記録は %LOGFILE% に保存しました）
echo ============================================================
echo.
pause
