<#
.SYNOPSIS
    社内つぶやきボード Day0 Doctor (Windows 側)
.DESCRIPTION
    Pleiades / WSL2 / Podman Desktop / Git for Windows / C:\workspace の状態を検査する。
    WSL 内部の検査は scripts/doctor.sh で行う (本スクリプト最後に案内を出す)。
#>
[CmdletBinding()]
param(
    [switch]$Quick
)

$ErrorActionPreference = "Continue"

$script:PASS = 0
$script:WARN = 0
$script:FAIL = 0

function Write-Section($name) {
    Write-Host ""
    Write-Host "== $name ==" -ForegroundColor Cyan
}

function Write-Ok($msg) {
    Write-Host "  [ OK ] $msg" -ForegroundColor Green
    $script:PASS++
}

function Write-Warn2($msg) {
    Write-Host "  [WARN] $msg" -ForegroundColor Yellow
    $script:WARN++
}

function Write-Ng($msg) {
    Write-Host "  [ NG ] $msg" -ForegroundColor Red
    $script:FAIL++
}

# --- 1. Windows バージョン ----------------------------------------------
Write-Section "Windows"
$winVer = (Get-CimInstance Win32_OperatingSystem).Caption
if ($winVer -match "Windows 11") {
    Write-Ok $winVer
} else {
    Write-Warn2 "Windows 11 でない: $winVer"
}

# --- 2. 管理者権限 -------------------------------------------------------
Write-Section "Administrator"
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($isAdmin) {
    Write-Ok "管理者として実行中"
} else {
    Write-Warn2 "管理者権限なしで実行中 (キッティング時のみ管理者必須)"
}

# --- 3. Pleiades --------------------------------------------------------
Write-Section "Pleiades (Eclipse)"
if (Test-Path "C:\Pleiades") {
    Write-Ok "C:\Pleiades 配置済み"
    if (Test-Path "C:\Pleiades\eclipse\eclipse.exe") {
        Write-Ok "eclipse.exe 確認"
    } else {
        Write-Warn2 "C:\Pleiades はあるが eclipse\eclipse.exe が見つからない"
    }
} else {
    Write-Ng "C:\Pleiades が見つからない — 手動配置が必要"
}

# --- 4. WSL2 ------------------------------------------------------------
Write-Section "WSL2"
$wslCmd = Get-Command wsl -ErrorAction SilentlyContinue
if (-not $wslCmd) {
    Write-Ng "wsl.exe が見つからない"
} else {
    $wslOutput = wsl --list --verbose 2>&1 | Out-String
    if ($LASTEXITCODE -eq 0 -and $wslOutput) {
        Write-Ok "wsl --list --verbose 成功"
        if ($wslOutput -match "Ubuntu") {
            Write-Ok "Ubuntu ディストリ確認"
        } else {
            Write-Warn2 "Ubuntu ディストリが見つからない"
        }
        if ($wslOutput -match "2\s*$" -or $wslOutput -match "VERSION") {
            Write-Ok "WSL バージョン情報を取得"
        }
    } else {
        Write-Ng "wsl --list が失敗"
    }
}

# --- 5. Podman Desktop --------------------------------------------------
Write-Section "Podman Desktop"
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
if ($wingetCmd) {
    $podmanList = winget list --id RedHat.Podman-Desktop 2>$null | Out-String
    if ($podmanList -match "Podman") {
        Write-Ok "Podman Desktop インストール済み"
    } else {
        Write-Warn2 "Podman Desktop が winget に見つからない (手動インストール済みなら無視可)"
    }
} else {
    Write-Warn2 "winget が使えない"
}

# --- 6. Git for Windows -------------------------------------------------
Write-Section "Git for Windows"
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
    Write-Ok "git: $(git --version)"
    $autocrlf = git config --global core.autocrlf
    if ($autocrlf -eq "input") {
        Write-Ok "core.autocrlf=input"
    } else {
        Write-Warn2 "core.autocrlf=$autocrlf (input 推奨)"
    }
} else {
    Write-Ng "git が見つからない"
}

# --- 7. C:\workspace ----------------------------------------------------
Write-Section "C:\workspace"
if (Test-Path "C:\workspace") {
    Write-Ok "C:\workspace 存在"
    try {
        $testFile = "C:\workspace\.doctor-write-test"
        New-Item -ItemType File -Path $testFile -Force | Out-Null
        Remove-Item $testFile -Force
        Write-Ok "書き込み可能"
    } catch {
        Write-Ng "C:\workspace に書き込み不可: $_"
    }
} else {
    Write-Ng "C:\workspace がない"
}

# --- サマリ -------------------------------------------------------------
Write-Host ""
Write-Host "=== Doctor (Windows) Summary ===" -ForegroundColor Cyan
Write-Host ("  PASS: {0}    WARN: {1}    FAIL: {2}" -f $script:PASS, $script:WARN, $script:FAIL)
Write-Host ""
Write-Host "次のステップ — WSL 側の検査:" -ForegroundColor Cyan
Write-Host "  wsl bash /mnt/c/workspace/<your-repo>/scripts/doctor.sh"

if ($script:FAIL -gt 0) {
    exit 1
}
exit 0
