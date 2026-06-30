<#
.SYNOPSIS
    社内つぶやきボード Windows 側キッティング (要管理者)
.DESCRIPTION
    WSL2 / Ubuntu / Podman Desktop / Git for Windows / Windows Terminal を導入し、
    C:\workspace を作成する。Pleiades は手動配置前提なので、存在検査のみ。
.PARAMETER Rollback
    主要パッケージを逆順 uninstall する (WSL ディストリは保護)
.PARAMETER DryRun
    実際の install は行わず、何をやるかだけ表示する
.EXAMPLE
    Set-ExecutionPolicy -Scope Process Bypass; .\scripts\setup.ps1
#>
[CmdletBinding()]
param(
    [switch]$Rollback,
    [switch]$DryRun
)

$ErrorActionPreference = "Continue"
$env:WSL_UTF8 = "1"  # wsl.exe 出力を UTF-8 化し文字化け/誤判定を防ぐ

# --- 管理者チェック ----------------------------------------------------
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "管理者として実行してください。"
    exit 1
}

# --- ログ Transcript --------------------------------------------------
# 注: このパスは かんたんセットアップ\bin\setup1-windows.ps1 の失敗時案内文にも
# 記載されている。変更する場合は両方を更新すること。
$logDir = "C:\workspace\.kitting"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}
$logFile = Join-Path $logDir ("setup-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
Start-Transcript -Path $logFile -Append | Out-Null

try {
    if ($Rollback) {
        Write-Host "Rollback モード: 主要パッケージを uninstall (WSL ディストリは保護)" -ForegroundColor Yellow
        @("RedHat.Podman-Desktop", "Git.Git", "Microsoft.WindowsTerminal") | ForEach-Object {
            Write-Host "  uninstalling $_..."
            winget uninstall --id $_ --silent --accept-source-agreements 2>$null
        }
        return
    }

    # --- winget 確認 ------------------------------------------------
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Error "winget が見つかりません。Microsoft Store から 'App Installer' をインストールしてください。"
        exit 1
    }

    # --disable-interactivity は winget 1.4 以降のみ対応。古い winget では未対応
    # フラグとしてエラーになり install が失敗するため、版数を見て付与を判断する。
    $script:SupportsDisableInteractivity = $false
    try {
        $wingetVersion = ((winget --version) | Out-String) -replace '[^\d.]', ''
        if ($wingetVersion) {
            $script:SupportsDisableInteractivity = [version]$wingetVersion -ge [version]'1.4'
        }
    } catch {}

    # インストール失敗を集計し、末尾で exit code に反映する
    # (これが無いと失敗しても exit 0 になり、呼び出し元バッチが「完了」と誤表示する)
    $script:InstallFailed = @()

    function Install-IfMissing {
        param(
            [string]$Id,
            [string]$Name
        )
        $listOut = winget list --id $Id --exact --accept-source-agreements 2>$null | Out-String
        if ($listOut -match [regex]::Escape($Id)) {
            Write-Host "  [SKIP] $Name は既にインストール済み" -ForegroundColor Green
            return
        }
        Write-Host "  [INSTALL] $Name ..."
        if (-not $DryRun) {
            $wingetArgs = @(
                "install", "--id", $Id, "--silent",
                "--accept-package-agreements", "--accept-source-agreements"
            )
            # --disable-interactivity: 進捗スピナー等の制御文字が Transcript ログに
            # 混入するのを防ぐ。winget 1.4 未満は未対応のため版数を見て付与する。
            if ($script:SupportsDisableInteractivity) {
                $wingetArgs += "--disable-interactivity"
            }
            winget @wingetArgs
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "  $Name のインストールに失敗 (exit=$LASTEXITCODE)"
                $script:InstallFailed += $Name
            }
        }
    }

    # --- 1. WSL2 機能 ----------------------------------------------
    Write-Host ""
    Write-Host "==> WSL2 機能を有効化" -ForegroundColor Cyan
    $vmpFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if ($vmpFeature.State -ne "Enabled" -or $wslFeature.State -ne "Enabled") {
        Write-Host "  WSL2 機能を有効化します (完了後に再起動が必要)" -ForegroundColor Yellow
        if (-not $DryRun) {
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -All | Out-Null
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -All | Out-Null
        }
    } else {
        Write-Host "  WSL2 機能は有効済み" -ForegroundColor Green
    }
    if (-not $DryRun) {
        wsl --set-default-version 2 2>$null | Out-Null
    }

    # --- 2. Ubuntu 22.04 -------------------------------------------
    Write-Host ""
    Write-Host "==> Ubuntu 22.04 ディストリ" -ForegroundColor Cyan
    $wslList = wsl --list 2>$null | Out-String
    if ($wslList -notmatch "Ubuntu-22\.04") {
        Write-Host "  Ubuntu-22.04 をインストール中..."
        if (-not $DryRun) {
            wsl --install -d Ubuntu-22.04 --no-launch
        }
    } else {
        Write-Host "  Ubuntu-22.04 は既にインストール済み" -ForegroundColor Green
    }

    # --- 3. winget パッケージ --------------------------------------
    Write-Host ""
    Write-Host "==> winget でパッケージをインストール" -ForegroundColor Cyan
    Install-IfMissing -Id "Git.Git" -Name "Git for Windows"
    Install-IfMissing -Id "RedHat.Podman-Desktop" -Name "Podman Desktop"
    Install-IfMissing -Id "Microsoft.WindowsTerminal" -Name "Windows Terminal"

    # --- 4. git 設定 ----------------------------------------------
    Write-Host ""
    Write-Host "==> Git 設定 (core.autocrlf=input)" -ForegroundColor Cyan
    if (Get-Command git -ErrorAction SilentlyContinue) {
        if (-not $DryRun) {
            git config --global core.autocrlf input
        }
        Write-Host "  core.autocrlf=input を設定" -ForegroundColor Green
    } else {
        Write-Warning "  git がまだ PATH にないので、新しいシェルで再度実行してください"
    }

    # --- 5. C:\workspace -------------------------------------------
    Write-Host ""
    Write-Host "==> C:\workspace を作成" -ForegroundColor Cyan
    if (-not (Test-Path "C:\workspace")) {
        New-Item -ItemType Directory -Force -Path "C:\workspace" | Out-Null
        Write-Host "  C:\workspace を作成" -ForegroundColor Green
    } else {
        Write-Host "  C:\workspace は既存" -ForegroundColor Green
    }

    # --- 6. Pleiades 検査 ----------------------------------------
    Write-Host ""
    Write-Host "==> Pleiades 検査" -ForegroundColor Cyan
    if (Test-Path "C:\Pleiades") {
        Write-Host "  C:\Pleiades 配置済み" -ForegroundColor Green
    } else {
        Write-Warning "  C:\Pleiades が見つかりません。手動配置してください。"
    }

    # --- 7. OPENAI_API_KEY ヒント（WSL 側 ~/.bashrc が正本）-------
    Write-Host ""
    Write-Host "==> OPENAI_API_KEY" -ForegroundColor Cyan
    Write-Host "  本研修では Codex CLI を WSL Ubuntu 上で動かすため、" -ForegroundColor Yellow
    Write-Host "  OPENAI_API_KEY は **WSL 側の ~/.bashrc に設定** します。" -ForegroundColor Yellow
    Write-Host "  Windows 側の User 環境変数は WSL に伝搬しないため、こちらには入れません。"
    Write-Host "  詳細手順は education/student-setup-guide.md §7 を参照。"

    if ($script:InstallFailed.Count -gt 0) {
        Write-Host ""
        Write-Warning ("インストールに失敗したパッケージ: " + ($script:InstallFailed -join ", "))
        Write-Warning "ネットワーク等を確認して、このセットアップを再実行してください。"
        Write-Warning "ログファイル: $logFile"
        exit 1
    }

    Write-Host ""
    Write-Host "==> Windows 側セットアップ完了" -ForegroundColor Green
    Write-Host ""
    Write-Host "次のステップ:" -ForegroundColor Cyan
    Write-Host "  1. PC を再起動 (WSL2 機能の有効化を反映)"
    Write-Host "  2. スタートメニュー → 'Ubuntu' を起動 → 初回ユーザ名・パスワードを設定"
    Write-Host "  3. 'かんたんセットアップ' フォルダの「セットアップ2_Ubuntu準備.bat」をダブルクリック"
    Write-Host "  4. 続けて「セットアップ3_APIキー設定.bat」→「環境チェック.bat」をダブルクリック"
    Write-Host ""
    Write-Host "（上級者向け）手動で行う場合: cd /mnt/c/workspace/<repo> && bash scripts/setup-wsl.sh"
    Write-Host "詳細手順: education/student-setup-guide.md §4-5 以降"
    Write-Host "ログファイル: $logFile"
}
finally {
    Stop-Transcript | Out-Null
}
pause
