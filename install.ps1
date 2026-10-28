<#
.SYNOPSIS
  Install skills by flattening skills\<category>\<skill> into an agent's skills folder.

.EXAMPLE
  .\install.ps1                                  # all skills -> ~\.claude\skills
  .\install.ps1 -Agent codex                     # -> ~\.codex\skills
  .\install.ps1 -Agent project                   # -> .\.claude\skills (current folder)
  .\install.ps1 -Target D:\agents\skills         # any folder
  .\install.ps1 -Only core,dotnet,database       # selected categories
  .\install.ps1 -Link                            # junctions instead of copies (git pull updates all)
  .\install.ps1 -List                            # list categories and counts
#>
[CmdletBinding()]
param(
    [ValidateSet('claude', 'codex', 'gemini', 'project')]
    [string]   $Agent = 'claude',
    [string]   $Target,
    [string[]] $Only,
    [switch]   $Link,
    [switch]   $List
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$src = Join-Path $PSScriptRoot 'skills'

# Accept both -Only core,dotnet (array) and -Only "core,dotnet" (single string, e.g. via pwsh -File)
if ($Only) { $Only = @($Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }

if ($List) {
    Get-ChildItem $src -Directory | ForEach-Object {
        $n = (Get-ChildItem $_.FullName -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') }).Count
        '{0,-14} {1} skills' -f $_.Name, $n
    }
    return
}

if (-not $Target) {
    $Target = switch ($Agent) {
        'claude'  { Join-Path $HOME '.claude\skills' }
        'codex'   { Join-Path $HOME '.codex\skills' }
        'gemini'  { Join-Path $HOME '.gemini\skills' }
        'project' { Join-Path (Get-Location) '.claude\skills' }
    }
}
New-Item -ItemType Directory -Force -Path $Target | Out-Null

$count = 0
foreach ($cat in Get-ChildItem $src -Directory) {
    if ($Only -and ($Only -notcontains $cat.Name)) { continue }
    foreach ($skill in Get-ChildItem $cat.FullName -Directory) {
        if (-not (Test-Path (Join-Path $skill.FullName 'SKILL.md'))) { continue }
        $dest = Join-Path $Target $skill.Name
        if (Test-Path $dest) {
            $item = Get-Item $dest -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $item.Delete() }   # remove link only, never its target
            else { Remove-Item $dest -Recurse -Force }
        }
        if ($Link) {
            # Junctions need no admin rights on Windows; on Linux/macOS use symlinks.
            $onWindows = ($PSVersionTable.PSVersion.Major -lt 6) -or $IsWindows
            $linkType = if ($onWindows) { 'Junction' } else { 'SymbolicLink' }
            New-Item -ItemType $linkType -Path $dest -Target $skill.FullName | Out-Null
        }
        else       { Copy-Item $skill.FullName -Destination $dest -Recurse }
        $count++
    }
}
$mode = if ($Link) { 'link' } else { 'copy' }
Write-Host "Installed $count skills ($mode) into $Target"
