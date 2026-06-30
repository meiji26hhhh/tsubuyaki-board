# =========================================================================
# セットアップ 手順1 : Windows の準備 (管理者権限が必要)
#   WSL2 / Ubuntu / Podman Desktop / Git for Windows を導入する。
#   実処理は scripts\setup.ps1 が担う。本スクリプトは昇格と案内のみ。
# =========================================================================
. "$PSScriptRoot\_common.ps1"

# 管理者でなければ自己昇格して再実行する
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "管理者権限が必要です。確認画面が出たら「はい」を押してください..."
    try {
        # 昇格した別ウィンドウで続きを実行する (このウィンドウはここで役目を終える)
        Start-Process powershell -Verb RunAs -ArgumentList @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`""
        )
    } catch {
        # UAC で「いいえ」を選ぶと例外になる。生エラーのまま閉じると受講生が
        # 読めないため、案内を出して明示的に失敗させる。
        Write-Banner -Color "Red" -Lines @(
            " [中止] 管理者権限が許可されませんでした。",
            " もう一度バッチをダブルクリックし、確認画面で「はい」を押してください。"
        )
        Wait-Enter
        exit 1
    }
    exit 0
}

Write-Banner -Lines @(
    " Windows の準備を始めます。しばらくお待ちください。",
    " （WSL2 / Ubuntu / Podman Desktop / Git を入れます）"
)

$repo = Get-RepoRoot
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo "scripts\setup.ps1")
$rc = $LASTEXITCODE

if ($rc -ne 0) {
    Write-Banner -Color "Red" -Lines @(
        " WIndowsのセットアップ処理が完了しました。",
        " 詳しい記録は C:\workspace\.kitting\ の setup-日付.log にあります。",
        " 解決しない場合は、この画面とそのログを講師にお見せください。"
    )
    Wait-Enter
    exit 1
}

Write-Banner -Lines @(
    " 手順1 はここまでです。",
    "",
    " この後の流れ:",
    "   1) いったん PC を再起動してください。（とても重要です）",
    "   2) スタートメニューから「Ubuntu」を起動し、新しいユーザー名とパスワードを決めて入力してください。",
    "   3) 「セットアップ2_Ubuntu準備.bat」をダブルクリックしてください。"
)
Wait-Enter
