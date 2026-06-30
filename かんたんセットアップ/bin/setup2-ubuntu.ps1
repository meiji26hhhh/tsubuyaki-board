# =========================================================================
# セットアップ 手順2 : Ubuntu の準備
#   手順1の後、PC再起動とUbuntu初回ログインを済ませてから実行する。
#   JDK 21 / Maven / Podman / Codex 環境を WSL Ubuntu 内に導入する。
# =========================================================================
. "$PSScriptRoot\_common.ps1"

Write-Banner -Lines @(
    " Ubuntu の準備を始めます。",
    " （JDK 21 / Maven / Podman / Codex 環境を入れます）",
    " 途中で「[sudo] password for ...」と画面に出て、パスワードを聞かれます。",
    " Ubuntu の初回ログインで決めたパスワードを入力してください。",
    " ★入力中は画面に文字が出ませんが、ちゃんと入力されています。",
    "   打ち終わったら Enter キーを押してください。",
    " 作業の記録は logs フォルダにも保存されます。"
)

$repo = Get-RepoRoot
$log = New-SetupLogPath -Prefix "setup2-ubuntu"

$rc = Invoke-WslLogged -RepoRoot $repo -LogFile $log -BashCommand "bash scripts/setup-wsl.sh"
if ($null -eq $rc) { Show-WslPathError; Wait-Enter; exit 1 }

if ($rc -ne 0) {
    Write-Banner -Color "Red" -Lines @(
        " セットアップ2の実行が完了しました。",
        " 次のファイルの記録をご確認ください:",
        "   $log",
        " Git,OPENAI_API_KEY,OralceXE以外がOKであることを確認してください。",
        " 解決しない場合は、このlogファイルを講師にお見せください。"
    )
    Wait-Enter
    exit 1
}

Write-Banner -Lines @(
    " 手順2 が完了しました。",
    " 次は「セットアップ3_APIキー設定.bat」をダブルクリックしてください。",
    " （作業の記録は $log に保存しました）"
)
Wait-Enter
