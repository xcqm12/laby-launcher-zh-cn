param(
    [string]$Path,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
. (Join-Path $PSScriptRoot 'Common.ps1')
$root = Split-Path $PSScriptRoot -Parent

Write-Host ''
Write-Host '==== Laby Launcher 简体中文补丁 ====' -ForegroundColor Cyan
Write-Host ''

$pkg = Join-Path $root 'i18n\zh-Hans.json'
if (-not (Test-Path $pkg)) { throw "语言包缺失：$pkg" }

$install = Get-LabyInstallDir -Override $Path
Write-Host "  安装目录：$install"

if (-not (Assert-LauncherStopped) -and -not $Force) {
    Write-Host '  已中止。请退出启动器后重试，或加 -Force 强制继续。' -ForegroundColor Yellow
    exit 1
}

$dirs = Get-I18nDirs -InstallDir $install
Write-Host '  备份原始文件…'
Backup-Originals -I18nDirs $dirs

foreach ($d in $dirs) {
    $dst = Join-Path $d 'zh-Hans.json'
    Copy-Item $pkg $dst -Force
    Write-Host "  已写入：$dst"
}

Set-LauncherLanguage -Language 'zh-Hans'

Write-Host '  校验…'
Show-Coverage -InstallDir $install -I18nDirs $dirs

Write-Host ''
Write-Host '  完成。启动启动器即为简体中文。' -ForegroundColor Green
Write-Host '  （设置路径：启动器设置 → 启动器语言 → 简体中文）'
Write-Host ''
