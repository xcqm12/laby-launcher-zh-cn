# Common.ps1 — Laby Launcher 汉化补丁公共函数
$script:BackupRoot = Join-Path $env:APPDATA 'LabyMod\zh-patch-backup'

function Get-LabyInstallDir {
    param([string]$Override)
    if ($Override) {
        if (Test-Path (Join-Path $Override 'resources')) { return (Resolve-Path $Override).Path }
        throw "指定路径无效（未找到 resources 目录）：$Override"
    }
    $cands = New-Object System.Collections.Generic.List[string]
    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
            $p = Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue
            if ($p.DisplayName -like '*Laby*' -and $p.UninstallString) {
                $exe = [string]$p.UninstallString
                if ($exe.StartsWith('"')) { $exe = $exe.Split('"')[1] } else { $exe = ($exe -split ' ')[0] }
                if ($exe) { $cands.Add((Split-Path $exe -Parent)) }
            }
        }
    }
    $x86 = [Environment]::GetEnvironmentVariable('ProgramFiles(x86)')
    $cands.Add((Join-Path $env:LOCALAPPDATA 'Programs\Laby Launcher'))
    $cands.Add((Join-Path $env:LOCALAPPDATA 'Laby Launcher'))
    $cands.Add((Join-Path $env:ProgramFiles 'Laby Launcher'))
    if ($x86) { $cands.Add((Join-Path $x86 'Laby Launcher')) }
    foreach ($c in $cands) {
        if (-not $c) { continue }
        if (Test-Path (Join-Path $c 'resources\app')) { return (Resolve-Path $c).Path }
        if (Test-Path (Join-Path $c 'resources\i18n')) { return (Resolve-Path $c).Path }
    }
    $msg = '未能自动找到 Laby Launcher 安装目录。请用 -Path 参数指定，例如：'
    $hint = '  powershell -ExecutionPolicy Bypass -File scripts\apply.ps1 -Path "D:\Games\Laby Launcher"'
    throw ($msg + [Environment]::NewLine + $hint)
}

function Get-I18nDirs {
    param([string]$InstallDir)
    $vite = Join-Path $InstallDir 'resources\app\.vite\i18n'
    $res  = Join-Path $InstallDir 'resources\i18n'
    $dirs = @()
    if (Test-Path $vite) { $dirs += $vite }
    if (Test-Path $res)  { $dirs += $res }
    if ($dirs.Count -eq 0) {
        New-Item -ItemType Directory -Force -Path $vite | Out-Null
        $dirs += $vite
    }
    return $dirs
}

function Get-ConfigPath { return (Join-Path $env:APPDATA 'LabyMod\launcher-config.json') }

function Assert-LauncherStopped {
    $names = @('LabyModLauncher','Laby Launcher','laby-launcher','LabyLauncher')
    foreach ($n in $names) {
        $p = Get-Process -Name $n -ErrorAction SilentlyContinue
        if ($p) {
            Write-Host ''
            Write-Host '  [!] 检测到启动器正在运行。' -ForegroundColor Yellow
            Write-Host '      请先完全退出启动器再执行，否则它退出时可能覆盖语言设置。' -ForegroundColor Yellow
            Write-Host ''
            return $false
        }
    }
    return $true
}

function Backup-Originals {
    param([string[]]$I18nDirs)
    New-Item -ItemType Directory -Force -Path $script:BackupRoot | Out-Null
    foreach ($d in $I18nDirs) {
        $src = Join-Path $d 'zh-Hans.json'
        if (-not (Test-Path $src)) { continue }
        $tag = if ($d -like '*.vite*') { 'zh-Hans.vite.json' } else { 'zh-Hans.resources.json' }
        $dst = Join-Path $script:BackupRoot $tag
        if (-not (Test-Path $dst)) { Copy-Item $src $dst -Force; Write-Host "  已备份原始文件：$tag" }
    }
    $cfg = Get-ConfigPath
    if (Test-Path $cfg) {
        $dst = Join-Path $script:BackupRoot 'launcher-config.json'
        if (-not (Test-Path $dst)) { Copy-Item $cfg $dst -Force; Write-Host '  已备份原始配置：launcher-config.json' }
    }
}

function Set-LauncherLanguage {
    param([string]$Language = 'zh-Hans')
    $cfg = Get-ConfigPath
    if (-not (Test-Path $cfg)) {
        Write-Host '  未找到 launcher-config.json（首次启动后才会生成），可在设置中手动选择“简体中文”'
        return
    }
    $obj = (Get-Content $cfg -Raw -Encoding UTF8) | ConvertFrom-Json
    $has = $obj.PSObject.Properties.Name -contains 'language'
    if ($has -and $obj.language -eq $Language) { Write-Host "  language 已为 $Language"; return }
    if ($has) { $obj.language = $Language }
    else { $obj | Add-Member -NotePropertyName language -NotePropertyValue $Language }
    ($obj | ConvertTo-Json -Depth 32) | Set-Content -Path $cfg -Encoding UTF8
    Write-Host "  已写入 language=$Language"
}

function Add-FlatEntry {
    param($Node, [string]$Prefix, $Acc)
    if ($null -eq $Node) { return }
    if ($Node -is [System.Array]) { return }
    foreach ($p in $Node.PSObject.Properties) {
        $v = $p.Value
        $k = $Prefix + $p.Name
        if ($null -eq $v) { continue }
        if ($v -is [System.Management.Automation.PSCustomObject]) { Add-FlatEntry -Node $v -Prefix ($k + '.') -Acc $Acc }
        elseif ($v -is [System.Array]) { continue }
        else { $Acc[$k] = [string]$v }
    }
}

function Get-FlatMap {
    param([string]$Path)
    $acc = @{}
    $json = (Get-Content $Path -Raw -Encoding UTF8) | ConvertFrom-Json
    Add-FlatEntry -Node $json -Prefix '' -Acc $acc
    return $acc
}

function Show-Coverage {
    param([string]$InstallDir, [string[]]$I18nDirs)
    $enPath = $null
    foreach ($d in $I18nDirs) { $c = Join-Path $d 'en.json'; if (Test-Path $c) { $enPath = $c; break } }
    if (-not $enPath) { Write-Host '  跳过校验：未找到 en.json'; return }
    $en = Get-FlatMap -Path $enPath
    $zhPath = Join-Path $I18nDirs[0] 'zh-Hans.json'
    if (-not (Test-Path $zhPath)) { Write-Host '  校验失败：未找到已安装的 zh-Hans.json' -ForegroundColor Red; return }
    $zh = Get-FlatMap -Path $zhPath
    $total = $en.Keys.Count
    $covered = 0
    foreach ($k in $en.Keys) { if ($zh.ContainsKey($k)) { $covered++ } }
    $ratio = 0.0
    if ($total -gt 0) { $ratio = $covered / $total }
    $registered = $ratio -ge 0.6
    Write-Host ('  覆盖率：{0}/{1} = {2:P2}' -f $covered, $total, $ratio)
    if ($registered) {
        $note = if ($ratio -ge 0.9999) { '完整，无英文兜底' } else { '不完整，缺失键将回落英文' }
        Write-Host ('  超过启动器 60% 注册门槛：通过（' + $note + '）') -ForegroundColor Green
    } else {
        Write-Host '  未达启动器 60% 注册门槛：语言不会出现在列表中' -ForegroundColor Red
    }
}
