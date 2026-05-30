@echo off
chcp 65001 >nul
set "WSL_UTF8=1"
rem ============================================================
rem  研修終了後のあと片付け : 開発環境(Ubuntu-22.04)を丸ごと削除します。
rem  研修の最終日に、PC をきれいに戻したいときだけ使います。
rem ============================================================

echo.
echo ============================================================
echo  ★重要な注意 — この操作は元に戻せません。
echo.
echo  WSL の Ubuntu-22.04 を「丸ごと」削除します。
echo  次のものがすべて一緒に消えます:
echo    ・Oracle のデータ（作成した表やデータ）
echo    ・あなたが書いたコードのうち Ubuntu 内に置いたもの
echo    ・JDK / Maven / Podman / Codex などの開発ツール
echo    ・OPENAI_API_KEY などの設定
echo.
echo  （Windows 側のアプリや C:\workspace などのフォルダは残ります）
echo ============================================================
echo.
echo  もう一度この環境を使うには「セットアップ1_Windows準備.bat」から
echo  やり直すことになります。
echo.

set "ANSWER="
set /p ANSWER="本当に削除する場合は、半角で delete と入力して Enter: "
if /i not "%ANSWER%"=="delete" (
echo.
echo 中止しました。何も削除していません。
echo.
pause
exit /b
)

rem --- ログの保存先を用意（削除を実行すると決まってから作成） ---
set "LOGDIR=%~dp0logs"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f "usebackq delims=" %%t in (`powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"`) do set "TS=%%t"
if not defined TS set "TS=latest"
set "LOGFILE=%LOGDIR%\uninstall_%TS%.log"

echo.
echo Ubuntu-22.04 を削除しています。少しお待ちください...
echo.

wsl --unregister Ubuntu-22.04 > "%LOGFILE%" 2>&1

if errorlevel 1 (
echo.
echo ============================================================
echo  [失敗] 削除できませんでした。
echo  ※ すでに削除済みの場合も、このエラー表示になります。
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
echo  削除が完了しました。研修おつかれさまでした。
echo  再びこの環境を使うときは「セットアップ1_Windows準備.bat」から
echo  やり直してください。
echo ============================================================
echo.
pause
