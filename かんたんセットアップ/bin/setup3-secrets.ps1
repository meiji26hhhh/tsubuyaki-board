# =========================================================================
# セットアップ 手順3 : API キー・Git 設定
#   Codex CLI が使う OPENAI_API_KEY と .env、Git のユーザー情報を設定する。
#   秘密情報は WSL 内で完結させ、Windows のコマンドラインには一切載せない。
# =========================================================================
. "$PSScriptRoot\_common.ps1"

Write-Banner -Lines @(
    " Codex CLI 用の API キーを設定します。",
    " 講師から渡された OPENAI_API_KEY（sk- で始まる文字列）を用意してください。",
    " ★貼り付けると画面に表示されますが、ログには残りません。",
    "   貼り付けたら必ず Enter キーを押してください。",
    " ★sk- で始まらないと数回やり直しになります。落ち着いて貼り直してください。",
    " ★API キーのあとに、コミットの作者として記録される「ユーザー名」と",
    "   「メールアドレス」も聞かれます（GitHub のものを推奨）。"
)

$repo = Get-RepoRoot
$log = New-SetupLogPath -Prefix "setup3-secrets"

$rc = Invoke-WslInteractive -RepoRoot $repo -BashCommand "bash scripts/setup-secrets.sh"

#if ($null -eq $rc) { Show-WslPathError; Wait-Enter; exit 1 }
#
#if ($rc -ne 0) {
#    Write-Banner -Color "Red" -Lines @(
#        " [失敗] API キーの設定でエラーが発生しました。",
#        " 画面の表示と、次のファイルの記録をご確認ください:",
#        "   $log",
#        " 解決しない場合は、このファイルを講師にお見せください。"
#    )
#    Wait-Enter
#    exit 1
#}

Write-Banner -Lines @(
    " 手順3 が完了しました。",
    " 次は「環境チェック.bat」をダブルクリックして、準備ができているか確認してください。",
    " （作業の記録は $log に保存しました）"
)
Wait-Enter
