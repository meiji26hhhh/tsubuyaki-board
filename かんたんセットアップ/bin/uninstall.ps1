# =========================================================================
# 研修終了後のあと片付け : 開発環境(Ubuntu-22.04)を丸ごと削除する。
#   研修の最終日に PC をきれいに戻したいときだけ使う。元に戻せない。
# =========================================================================
. "$PSScriptRoot\_common.ps1"

Write-Banner -Color "Yellow" -Lines @(
    " ★重要な注意 — この操作は元に戻せません。",
    "",
    " WSL の Ubuntu-22.04 を「丸ごと」削除します。",
    " 次のものがすべて一緒に消えます:",
    "   ・Oracle のデータ（作成した表やデータ）",
    "   ・あなたが書いたコードのうち Ubuntu 内に置いたもの",
    "   ・JDK / Maven / Podman / Codex などの開発ツール",
    "   ・OPENAI_API_KEY などの設定",
    "",
    " （Windows 側のアプリや C:\workspace などのフォルダは残ります）",
    "",
    " もう一度この環境を使うには「セットアップ1_Windows準備.bat」から",
    " やり直すことになります。"
)

# 削除対象が存在しない場合は、確認を出さずに「削除済み」と案内して終了する
$distroFound = $false
try {
    $distroList = & wsl --list --quiet 2>$null | Out-String
    if ($LASTEXITCODE -eq 0 -and $distroList -match "Ubuntu-22\.04") {
        $distroFound = $true
    }
} catch {
    # wsl.exe 自体が無い場合も「削除済み」扱いでよい
}
if (-not $distroFound) {
    Write-Banner -Lines @(
        " Ubuntu-22.04 は見つかりませんでした。",
        " すでに削除済みのため、何もする必要はありません。"
    )
    Wait-Enter
    exit 0
}

$answer = Read-Host "本当に削除する場合は、半角で delete と入力して Enter"
if ($answer -ne "delete") {
    Write-Host ""
    Write-Host "中止しました。何も削除していません。"
    Wait-Enter
    exit 0
}

Write-Host ""
Write-Host "Ubuntu-22.04 を削除しています。少しお待ちください..."
Write-Host ""

$log = New-SetupLogPath -Prefix "uninstall"
$output = & wsl --unregister Ubuntu-22.04 2>&1
$rc = $LASTEXITCODE
$output | Out-File -LiteralPath $log -Encoding utf8

if ($rc -ne 0) {
    Write-Banner -Color "Red" -Lines @(
        " 削除が処理が完了しました。",
        " 詳しい記録は次のファイルに保存されています:",
        "   $log",
        " 解決しない場合は、このファイルを講師にお見せください。"
    )
    Wait-Enter
    exit 1
}

Write-Banner -Lines @(
    " 削除が完了しました。研修おつかれさまでした。",
    " 再びこの環境を使うときは「セットアップ1_Windows準備.bat」から",
    " やり直してください。"
)
Wait-Enter
