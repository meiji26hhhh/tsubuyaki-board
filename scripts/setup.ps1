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

# --- 管理者チェック ----------------------------------------------------
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "管理者として実行してください。"
    exit 1
}

# --- ログ Transcript --------------------------------------------------
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

    function Install-IfMissing {
        param(
            [string]$Id,
            [string]$Name
        )
        $listOut = winget list --id $Id --exact --accept-source-agreements 2>$null | Out-String
        if ($listOut -match $Id) {
            Write-Host "  [SKIP] $Name は既にインストール済み" -ForegroundColor Green
            return
        }
        Write-Host "  [INSTALL] $Name ..."
        if (-not $DryRun) {
            winget install --id $Id --silent `
                --accept-package-agreements --accept-source-agreements
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
    if ($wslList -notmatch "Ubuntu") {
        Write-Host "  Ubuntu-22.04 をインストール中..."
        if (-not $DryRun) {
            wsl --install -d Ubuntu-22.04 --no-launch
        }
    } else {
        Write-Host "  Ubuntu は既にインストール済み" -ForegroundColor Green
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

    # --- 7. OPENAI_API_KEY のヒント ------------------------------
    Write-Host ""
    Write-Host "==> OPENAI_API_KEY" -ForegroundColor Cyan
    $existingKey = [Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")
    if ($existingKey) {
        Write-Host "  OPENAI_API_KEY は User 環境変数に設定済み" -ForegroundColor Green
    } else {
        Write-Host "  未設定。後で次のコマンドで設定してください:" -ForegroundColor Yellow
        Write-Host "    [Environment]::SetEnvironmentVariable('OPENAI_API_KEY', 'sk-...', 'User')"
    }

    Write-Host ""
    Write-Host "==> Windows 側セットアップ完了" -ForegroundColor Green
    Write-Host ""
    Write-Host "次のステップ (WSL を一度起動して初期ユーザを作成した後):" -ForegroundColor Cyan
    Write-Host "  1. リポジトリを C:\workspace 配下にクローン"
    Write-Host "  2. wsl bash /mnt/c/workspace/<repo>/scripts/setup-wsl.sh"
    Write-Host "  3. wsl bash /mnt/c/workspace/<repo>/scripts/doctor.sh"
    Write-Host ""
    Write-Host "ログファイル: $logFile"
}
finally {
    Stop-Transcript | Out-Null
}
