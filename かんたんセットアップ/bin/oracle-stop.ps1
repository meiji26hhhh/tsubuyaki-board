# =========================================================================
# Oracle 停止 : Oracle XE コンテナを停止する。データはそのまま残る。
# =========================================================================
. "$PSScriptRoot\_common.ps1"

Write-Host ""
Write-Host "Oracle を停止しています..."
Write-Host ""

$repo = Get-RepoRoot
$log = New-SetupLogPath -Prefix "oracle-stop"

# 技術的な出力はすべてログファイルへ（画面には出さない）
$rc = Invoke-WslLogged -RepoRoot $repo -LogFile $log -BashCommand "bash scripts/stop-oracle.sh" -Quiet
if ($null -eq $rc) { Show-WslPathError; Wait-Enter; exit 1 }

if ($rc -ne 0) {
    Write-Banner -Color "Red" -Lines @(
        " 停止処理を完了しました。",
        " 詳しい記録は次のファイルに保存されています:",
        "   $log",
        " 解決しない場合は、このファイルを講師にお見せください。"
    )
    Wait-Enter
    exit 1
}

Write-Banner -Lines @(
    " 停止しました。データはそのまま残っています。",
    " （技術的な記録は $log に保存しました）"
)
Wait-Enter
