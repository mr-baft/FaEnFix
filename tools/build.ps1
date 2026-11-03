# ساخت dist\FaEnFix.exe روی سیستم خودتان
# پیش‌نیاز: AutoHotkey v2 (winget install AutoHotkey.AutoHotkey) و Ahk2Exe
#   Ahk2Exe را از https://github.com/AutoHotkey/Ahk2Exe/releases بگیرید یا از Dash خود AutoHotkey نصب کنید.
param([string]$Ahk2Exe = "")
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$ahkDirs = @("$env:LOCALAPPDATA\Programs\AutoHotkey", "$env:ProgramFiles\AutoHotkey")
if (-not $Ahk2Exe) {
    $Ahk2Exe = $ahkDirs | ForEach-Object { Get-ChildItem $_ -Recurse -Filter Ahk2Exe.exe -ErrorAction SilentlyContinue } |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $Ahk2Exe) { throw "Ahk2Exe.exe پیدا نشد. مسیرش را با -Ahk2Exe بدهید." }
$base = $ahkDirs | ForEach-Object { Get-ChildItem $_ -Recurse -Filter AutoHotkey64.exe -ErrorAction SilentlyContinue } |
    Where-Object { $_.FullName -match '\\v2\\' } | Select-Object -First 1 -ExpandProperty FullName
if (-not $base) { throw "AutoHotkey v2 پیدا نشد." }

if (-not (Test-Path dict\en.txt) -or -not (Test-Path dict\fa.txt)) { & "$PSScriptRoot\build-dict.ps1" }
New-Item -ItemType Directory -Force dist | Out-Null
$p = Start-Process $Ahk2Exe -Wait -PassThru -ArgumentList '/in', 'FaEnFix.ahk', '/out', 'dist\FaEnFix.exe', '/base', "`"$base`"", '/silent'
if ($p.ExitCode -ne 0) { throw "Ahk2Exe failed ($($p.ExitCode))" }
Get-Item dist\FaEnFix.exe
