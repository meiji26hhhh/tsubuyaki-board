# =========================================================================
# 環境チェック : セットアップが正しく終わっているかを診断する。
# =========================================================================
. "$PSScriptRoot\_common.ps1"

Write-Host ""
Write-Host "環境をチェックしています。しばらくお待ちください..."
Write-Host "（結果は画面に表示し、logs フォルダにも記録します）"
Write-Host ""

$repo = Get-RepoRoot
$log = New-SetupLogPath -Prefix "doctor"

$rc = Invoke-WslLogged -RepoRoot $repo -LogFile $log -BashCommand "bash scripts/doctor.sh --quick"
if ($null -eq $rc) { Show-WslPathError; Wait-Enter; exit 1 }

if ($rc -ne 0) {
    Write-Banner -Color "Red" -Lines @(
        " チェックが完了しました。",
        " 次のファイルの記録をご確認ください:",
        "   $log",
        " 解決しない場合は、このファイルを講師にお見せください。"
    )
    Wait-Enter
    exit 1
}

Write-Banner -Lines @(
    " ↑ PASS（緑）が並んでいれば準備完了です。",
    "   WARN（黄）は問題ありません。FAIL（赤）がなければ大丈夫です。",
    "",
    " 準備ができたら「Oracle起動.bat」をダブルクリックしてください。",
    " （診断結果は $log にも保存しました）"
)
Wait-Enter
