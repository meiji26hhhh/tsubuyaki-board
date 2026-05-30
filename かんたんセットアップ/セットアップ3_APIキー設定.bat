@echo off
chcp 65001 >nul
set "WSL_UTF8=1"
rem ============================================================
rem  社内つぶやきボード セットアップ 手順3 : API キーの設定
rem  （Codex CLI が使う OPENAI_API_KEY と .env を設定します）
rem ============================================================

rem --- リポジトリのルート（このフォルダの1つ上）を求める ---
for %%I in ("%~dp0..") do set "REPO=%%~fI"

rem --- ログの保存先を用意 ---
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%t"
if not defined TS set "TS=latest"
set "LOGFILE=%LOGDIR%\setup3-secrets_%TS%.log"

echo.
echo ============================================================
echo  Codex CLI 用の API キーを設定します。
echo  講師から渡された OPENAI_API_KEY（sk- で始まる文字列）を
echo  用意してください。
echo  ★貼り付けても画面には表示されませんが、ちゃんと入力されています。
echo    貼り付けたら必ず Enter キーを押してください。
echo  ★sk- で始まらないと数回やり直しになります。落ち着いて貼り直してください。
echo ============================================================
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

rem --- 実行（画面に出しつつログにも記録。API キー本体は画面にもログにも残りません） ---
wsl -d Ubuntu-22.04 -- bash -c "set -o pipefail; cd '%WREPO%' && bash scripts/setup-secrets.sh 2>&1 | tee '%WLOGFILE%'"

if errorlevel 1 (
echo.
echo ============================================================
echo  [失敗] API キーの設定でエラーが発生しました。
echo  画面の表示と、次のファイルの記録をご確認ください:
echo    %LOGFILE%
echo  解決しない場合は、このファイルを講師にお見せください。
echo ============================================================
echo.
pause
exit /b 1
)

echo.
echo ============================================================
echo  手順3 が完了しました。
echo  次は「環境チェック.bat」をダブルクリックして、
echo  準備ができているか確認してください。
echo  （作業の記録は %LOGFILE% に保存しました）
echo ============================================================
echo.
pause
