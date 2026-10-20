param([string]$Path)
$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
. (Join-Path $PSScriptRoot 'Common.ps1')

Write-Host ''
Write-Host '==== Laby Launcher 汉化还原 ====' -ForegroundColor Cyan
Write-Host ''

$install = Get-LabyInstallDir -Override $Path
Write-Host "  安装目录：$install"

if (-not (Test-Path $script:BackupRoot)) {
    Write-Host '  没有找到备份目录，可能从未打过补丁：' -ForegroundColor Yellow
    Write-Host "    $script:BackupRoot"
    exit 1
}

$dirs = Get-I18nDirs -InstallDir $install
$restored = 0
foreach ($d in $dirs) {
    $tag = if ($d -like '*.vite*') { 'zh-Hans.vite.json' } else { 'zh-Hans.resources.json' }
    $src = Join-Path $script:BackupRoot $tag
    if (-not (Test-Path $src)) { Write-Host "  跳过（无备份）：$tag"; continue }
    $dst = Join-Path $d 'zh-Hans.json'
    Copy-Item $src $dst -Force
    Write-Host "  已还原：$dst"
    $restored++
}

$cfgBackup = Join-Path $script:BackupRoot 'launcher-config.json'
$cfg = Get-ConfigPath
if ((Test-Path $cfgBackup) -and (Test-Path $cfg)) {
    Copy-Item $cfgBackup $cfg -Force
    Write-Host "  已还原配置：$cfg"
    $restored++
}

if ($restored -eq 0) {
    Write-Host '  没有可还原的文件。' -ForegroundColor Yellow
    exit 1
}

Write-Host '  校验（还原后的原始覆盖率）：'
Show-Coverage -InstallDir $install -I18nDirs $dirs

Write-Host ''
Write-Host '  已恢复官方原状。启动启动器将显示英文界面。' -ForegroundColor Green
Write-Host ''
