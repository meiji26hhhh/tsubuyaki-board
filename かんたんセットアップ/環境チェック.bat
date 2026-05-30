@echo off
chcp 65001 >nul
set "WSL_UTF8=1"
rem ============================================================
rem  社内つぶやきボード 環境チェック
rem  （セットアップが正しく終わっているかを診断します）
rem ============================================================

rem --- リポジトリのルート（このフォルダの1つ上）を求める ---
for %%I in ("%~dp0..") do set "REPO=%%~fI"

rem --- ログの保存先を用意 ---
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%t"
if not defined TS set "TS=latest"
set "LOGFILE=%LOGDIR%\doctor_%TS%.log"

echo.
echo 環境をチェックしています。しばらくお待ちください...
echo （結果は画面に表示し、logs フォルダにも記録します）
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

rem --- 実行（画面に出しつつログにも記録。終了コードはスクリプトのものを伝播） ---
wsl -d Ubuntu-22.04 -- bash -c "set -o pipefail; cd '%WREPO%' && bash scripts/doctor.sh --quick 2>&1 | tee '%WLOGFILE%'"

if errorlevel 1 (
echo.
echo ============================================================
echo  [失敗] FAIL（赤）の項目があります。
echo  画面の赤い行と、次のファイルの記録をご確認ください:
echo    %LOGFILE%
echo  解決しない場合は、このファイルを講師にお見せください。
echo ============================================================
echo.
pause
exit /b 1
)

echo.
echo ============================================================
echo  ↑ PASS（緑）が並んでいれば準備完了です。
echo    WARN（黄）は問題ありません。FAIL（赤）がなければ大丈夫です。
echo.
echo  準備ができたら「Oracle起動.bat」をダブルクリックしてください。
echo  （診断結果は %LOGFILE% にも保存しました）
echo ============================================================
echo.
pause
