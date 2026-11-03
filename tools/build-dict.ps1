# فرهنگ لغت‌های dict\en.txt و dict\fa.txt را می‌سازد (هر خط یک کلمه، به ترتیب پرکاربردی)
# منبع: https://github.com/hermitdave/FrequencyWords  (CC-BY-SA 4.0)
param([int]$Count = 50000)
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $root "dict"
New-Item -ItemType Directory -Force $dir | Out-Null
$base = "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018"
$utf8 = New-Object System.Text.UTF8Encoding $false

function Build($lang, $filter) {
    $raw = (Invoke-WebRequest "$base/$lang/${lang}_$($Count / 1000)k.txt" -UseBasicParsing).Content
    if ($raw -is [byte[]]) { $raw = [Text.Encoding]::UTF8.GetString($raw) }
    $seen = New-Object 'System.Collections.Generic.HashSet[string]'
    $out = New-Object System.Collections.Generic.List[string]
    foreach ($line in $raw -split "`r?`n") {
        $w = ($line -split ' ')[0]
        $w = & $filter $w
        if ($w -and $seen.Add($w)) { $out.Add($w) }
    }
    [IO.File]::WriteAllLines((Join-Path $dir "$lang.txt"), $out, $utf8)
    "$lang : $($out.Count) words"
}

Build "en" { param($w) $w = $w.ToLowerInvariant(); if ($w -cmatch "^[a-z][a-z']*$") { $w } }
Build "fa" {
    param($w)
    $w = $w.Replace([string][char]0x064A, [string][char]0x06CC).Replace([string][char]0x0649, [string][char]0x06CC).Replace([string][char]0x0643, [string][char]0x06A9)
    $w = $w -replace "[\p{Mn}\p{Cf}\p{Lm}]", ""          # اعراب، تطویل، نیم‌فاصله
    if ($w -match "^\p{IsArabic}+$" -and $w -notmatch "[\p{Nd}\p{P}\p{S}]") { $w }
}
