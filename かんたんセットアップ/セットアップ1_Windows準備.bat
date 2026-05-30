@echo off
chcp 65001 >nul
set "WSL_UTF8=1"
rem ============================================================
rem  社内つぶやきボード セットアップ 手順1 : Windows の準備
rem  （管理者権限が必要です。自動で「はい」を求める画面が出ます）
rem ============================================================

rem --- 管理者かどうか確認。管理者でなければ自動で昇格して再実行 ---
net session >nul 2>&1
if %errorlevel% neq 0 ( echo 管理者権限が必要です。確認画面が出たら「はい」を押してください... & powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs" & exit /b )

rem --- このバッチがある場所へ移動（昇格直後は System32 にいるため） ---
for %%I in ("%~dp0..") do set "REPO=%%~fI"
cd /d "%REPO%"

echo.
echo ============================================================
echo  Windows の準備を始めます。しばらくお待ちください。
echo  （WSL2 / Ubuntu / Podman Desktop / Git を入れます）
echo ============================================================
echo.

powershell -ExecutionPolicy Bypass -File "%REPO%\scripts\setup.ps1"

if errorlevel 1 (
echo.
echo ============================================================
echo  [失敗] エラーが発生しました。
echo  詳しい記録は C:\workspace\.kitting\ の setup-日付.log にあります。
echo  解決しない場合は、この画面とそのログを講師にお見せください。
echo ============================================================
echo.
pause
exit /b 1
)

echo.
echo ============================================================
echo  手順1 はここまでです。
echo.
echo  この後の流れ:
echo    1) いったん PC を再起動してください。（とても重要です）
echo    2) スタートメニューから「Ubuntu」を起動し、新しいユーザー名とパスワードを決めて入力してください。
echo    3) 「セットアップ2_Ubuntu準備.bat」をダブルクリックしてください。
echo ============================================================
echo.
pause
