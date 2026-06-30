# =========================================================================
# Oracle 削除 : Oracle XE コンテナとデータをすべて削除する。
#   最初からやり直したいときに使う。
# =========================================================================
. "$PSScriptRoot\_common.ps1"

Write-Banner -Color "Yellow" -Lines @(
    " ★注意: Oracle のデータをすべて削除します。",
    "   これまでに作った表やデータは元に戻せません。"
)

$answer = Read-Host "本当に削除しますか？ 削除する場合は y を入力して Enter"
if ($answer -ne "y" -and $answer -ne "Y") {
    Write-Host ""
    Write-Host "中止しました。何も削除していません。"
    Wait-Enter
    exit 0
}

Write-Host ""
Write-Host "Oracle を削除しています..."
Write-Host ""

$repo = Get-RepoRoot
$log = New-SetupLogPath -Prefix "oracle-purge"

# 技術的な出力はすべてログファイルへ（画面には出さない）
$rc = Invoke-WslLogged -RepoRoot $repo -LogFile $log -BashCommand "bash scripts/stop-oracle.sh --purge" -Quiet
if ($null -eq $rc) { Show-WslPathError; Wait-Enter; exit 1 }

if ($rc -ne 0) {
    Write-Banner -Color "Red" -Lines @(
        " 削除処理を完了しました。",
        " 詳しい記録は次のファイルに保存されています:",
        "   $log",
        " 解決しない場合は、このファイルを講師にお見せください。"
    )
    Wait-Enter
    exit 1
}

Write-Banner -Lines @(
    " 削除しました。",
    " もう一度使うには「Oracle起動.bat」をダブルクリックしてください。",
    " （技術的な記録は $log に保存しました）"
)
Wait-Enter
