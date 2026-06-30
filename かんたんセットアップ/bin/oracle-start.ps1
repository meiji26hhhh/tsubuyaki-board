# =========================================================================
# Oracle 起動 : Oracle XE コンテナを起動する。初回は数分かかる。
# =========================================================================
. "$PSScriptRoot\_common.ps1"

Write-Host ""
Write-Host "Oracle を起動しています。完了の表示が出るまでお待ちください..."
Write-Host "（初回は数分かかります。進捗を画面に表示しながら logs フォルダにも記録します）"
Write-Host ""

$repo = Get-RepoRoot
$log = New-SetupLogPath -Prefix "oracle-start"

$rc = Invoke-WslLogged -RepoRoot $repo -LogFile $log -BashCommand "bash scripts/start-oracle.sh"
if ($null -eq $rc) { Show-WslPathError; Wait-Enter; exit 1 }

if ($rc -ne 0) {
    Write-Banner -Color "Red" -Lines @(
        " 起動完了しました。",
        " 詳しい記録は次のファイルに保存されています:",
        "   $log",
        " 解決しない場合は、このファイルを講師にお見せください。"
    )
    Wait-Enter
    exit 1
}

Write-Banner -Lines @(
    " Oracle の準備ができました（起動成功）。",
    " ↑「Oracle XE is ready.」と接続情報が画面に表示されています。",
    "",
    " 接続情報（控え）:",
    "   URL      : jdbc:oracle:thin:@//localhost:1521/XEPDB1",
    "   User     : tsubuyaki",
    "   Password : .env の ORACLE_APP_PWD（初期値 tsubuyaki_pw）",
    "",
    " （技術的な記録は $log に保存しました）"
)
Wait-Enter
