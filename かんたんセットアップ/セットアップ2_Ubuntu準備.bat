@echo off
chcp 65001 >nul
set "WSL_UTF8=1"
rem ============================================================
rem  社内つぶやきボード セットアップ 手順2 : Ubuntu の準備
rem  （手順1の後、PC再起動とUbuntu初回ログインを済ませてから実行）
rem ============================================================

rem --- リポジトリのルート（このフォルダの1つ上）を求める ---
for %%I in ("%~dp0..") do set "REPO=%%~fI"

rem --- ログの保存先を用意 ---
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%t"
if not defined TS set "TS=latest"
set "LOGFILE=%LOGDIR%\setup2-ubuntu_%TS%.log"

echo.
echo ============================================================
echo  Ubuntu の準備を始めます。
echo  （JDK 21 / Maven / Podman / Codex 環境を入れます）
echo.
echo  途中で「[sudo] password for ...」と画面に出て、
echo  パスワードを聞かれます。
echo  Ubuntu の初回ログインで決めたパスワードを入力してください。
echo  ★入力中は画面に文字が出ませんが、ちゃんと入力されています。
echo    打ち終わったら Enter キーを押してください。
echo.
echo  作業の記録は logs フォルダにも保存されます。
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

rem --- 実行（画面に出しつつログにも記録。終了コードはスクリプトのものを伝播） ---
wsl -d Ubuntu-22.04 -- bash -c "set -o pipefail; cd '%WREPO%' && bash scripts/setup-wsl.sh 2>&1 | tee '%WLOGFILE%'"

if errorlevel 1 (
echo.
echo ============================================================
echo  [失敗] Ubuntu の準備でエラーが発生しました。
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
echo  手順2 が完了しました。
echo  次は「セットアップ3_APIキー設定.bat」をダブルクリックしてください。
echo  （作業の記録は %LOGFILE% に保存しました）
echo ============================================================
echo.
pause
