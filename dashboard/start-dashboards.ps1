#Requires -Version 5.1
# SPDX-License-Identifier: MIT
<#
.SYNOPSIS
  Start Hindsight Memory UI, optional Control Center, GitNexus web, and the local hub.
  Hidden processes only — no CMD/Windows Terminal windows.
  Does NOT open a browser unless -Open is passed.
  Does NOT start anything unless this script is invoked (skill / user / hub button).
#>
param(
  [switch]$Open,
  [switch]$SkipHindsightUi,
  [switch]$SkipControl,
  [switch]$SkipGitNexus,
  [switch]$SkipHub,
  [string]$Profile = "cursor"
)

$ErrorActionPreference = "Stop"

# Prefer user-local bins (same as ensure-daemon.ps1)
$userLocalBin = Join-Path $env:USERPROFILE ".local\bin"
$npmRoaming = Join-Path $env:APPDATA "npm"
$env:PATH = (@($userLocalBin, $npmRoaming, $env:PATH) -join ";")

$HostAddr = "127.0.0.1"
$HindsightApi = "http://${HostAddr}:9077"
$HindsightUi = "http://${HostAddr}:19077"
$ControlUrl = "http://${HostAddr}:7878"
$GitNexusUrl = "http://${HostAddr}:4747"
$HubUrl = "http://${HostAddr}:8765"

$ScriptDir = $PSScriptRoot
$RepoRoot = Split-Path -Parent $ScriptDir
$EnsureCandidates = @(
  (Join-Path $env:USERPROFILE ".hindsight\ensure-daemon.ps1"),
  (Join-Path $RepoRoot "scripts\ensure-daemon.ps1")
)
$HubServer = Join-Path $ScriptDir "hub-server.mjs"
$LogDir = Join-Path $env:USERPROFILE ".hindsight\logs"
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

if ($env:MEMORY_GRAPH_HUB_SKIP_SELF -eq "1") {
  $SkipHub = $true
}

function Test-Url([string]$Url) {
  try {
    $r = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
    return ($r.StatusCode -ge 200 -and $r.StatusCode -lt 500)
  } catch {
    return $false
  }
}

function Invoke-NoWindow {
  param(
    [Parameter(Mandatory = $true)][string]$FileName,
    [string]$Arguments = "",
    [string]$WorkingDirectory = $env:USERPROFILE,
    [switch]$Wait
  )
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $FileName
  $psi.Arguments = $Arguments
  $psi.WorkingDirectory = $WorkingDirectory
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  if ($psi.EnvironmentVariables.ContainsKey("PATH")) {
    $psi.EnvironmentVariables["PATH"] = $env:PATH
  }
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  [void]$p.Start()
  if ($Wait) {
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $p.WaitForExit()
    return @{
      ExitCode = $p.ExitCode
      StdOut   = $stdout
      StdErr   = $stderr
    }
  }
  # Detached background: drain streams asynchronously into logs
  return @{ ExitCode = 0; ProcessId = $p.Id; Process = $p }
}

function Find-GitNexusEntry {
  try {
    $npmRoot = (& npm root -g 2>$null | Select-Object -First 1)
  } catch {
    $npmRoot = $null
  }
  if (-not $npmRoot) { return $null }
  $cli = Join-Path $npmRoot "gitnexus\dist\cli\index.js"
  if (Test-Path -LiteralPath $cli) { return $cli }
  return $null
}

function Wait-Url([string]$Url, [int]$Seconds = 30) {
  $deadline = (Get-Date).AddSeconds($Seconds)
  while ((Get-Date) -lt $deadline) {
    if (Test-Url $Url) { return $true }
    Start-Sleep -Milliseconds 400
  }
  return (Test-Url $Url)
}

# 1) Hindsight API (on-demand ensure — same as Cursor MCP)
if (-not (Test-Url "$HindsightApi/health")) {
  $ensure = $EnsureCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
  if ($ensure) {
    & $ensure | Out-Null
  } else {
    Write-Warning "ensure-daemon.ps1 not found; start API via Cursor MCP or manually"
  }
}

$embed = Get-Command "hindsight-embed.exe" -ErrorAction SilentlyContinue
if (-not $embed) { $embed = Get-Command "hindsight-embed" -ErrorAction SilentlyContinue }

# 2) Memory UI (official control-plane package) — bind loopback only.
# hindsight-embed "ui start" often times out at 30s on cold npx; start the same
# package directly and wait longer.
if (-not $SkipHindsightUi -and -not (Test-Url $HindsightUi)) {
  $npxCmd = Get-Command "npx.cmd" -ErrorAction SilentlyContinue
  if (-not $npxCmd) { $npxCmd = Get-Command "npx" -ErrorAction SilentlyContinue }
  if ($npxCmd) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $npxCmd.Source
    $psi.Arguments = "-y @vectorize-io/hindsight-control-plane --port 19077 --hostname 127.0.0.1 --api-url $HindsightApi"
    $psi.WorkingDirectory = $env:USERPROFILE
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables["PATH"] = $env:PATH
    $psi.EnvironmentVariables["PORT"] = "19077"
    $psi.EnvironmentVariables["HOSTNAME"] = "127.0.0.1"
    $psi.EnvironmentVariables["HINDSIGHT_CP_DATAPLANE_API_URL"] = $HindsightApi
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    try {
      $p.Id | Set-Content -Path (Join-Path $LogDir "hindsight-ui.pid") -Encoding ascii
    } catch {}
    if (-not (Wait-Url $HindsightUi 120)) {
      Write-Warning "Memory UI did not become ready on $HindsightUi within 120s"
    }
  } elseif ($embed) {
    $null = Invoke-NoWindow -FileName $embed.Source -Arguments ("-p {0} ui start --port 19077 --hostname 127.0.0.1" -f $Profile) -Wait
    [void](Wait-Url $HindsightUi 45)
  } else {
    Write-Warning "npx / hindsight-embed not found; skip Memory UI"
  }
}

# 3) Control Center (optional supervisor + wizard)
if (-not $SkipControl -and -not (Test-Url $ControlUrl)) {
  if ($embed) {
    $null = Invoke-NoWindow -FileName $embed.Source -Arguments ("-p {0} control start --port 7878 --no-open" -f $Profile) -Wait
    [void](Wait-Url $ControlUrl 30)
  }
}

# 4) GitNexus serve (bundled web UI + /api/repos)
if (-not $SkipGitNexus -and -not (Test-Url "$GitNexusUrl/api/repos")) {
  $node = (Get-Command node -ErrorAction SilentlyContinue)
  $gn = Find-GitNexusEntry
  if ($node -and $gn) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $node.Source
    $psi.Arguments = "`"$gn`" serve --port 4747 --host 127.0.0.1"
    $psi.WorkingDirectory = $env:USERPROFILE
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables["PATH"] = $env:PATH
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    try {
      $p.Id | Set-Content -Path (Join-Path $LogDir "gitnexus-serve.pid") -Encoding ascii
    } catch {}
    [void](Wait-Url "$GitNexusUrl/api/repos" 30)
  } else {
    Write-Warning "gitnexus CLI / node not found; skip Graph UI"
  }
}

# 5) Integration hub
if (-not $SkipHub -and -not (Test-Url $HubUrl)) {
  $node = (Get-Command node -ErrorAction SilentlyContinue)
  if ($node -and (Test-Path -LiteralPath $HubServer)) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $node.Source
    $psi.Arguments = "`"$HubServer`""
    $psi.WorkingDirectory = $ScriptDir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.EnvironmentVariables["PATH"] = $env:PATH
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    [void](Wait-Url $HubUrl 15)
  }
}

$report = [ordered]@{
  hindsightApi = Test-Url "$HindsightApi/health"
  hindsightUi  = Test-Url $HindsightUi
  control      = Test-Url $ControlUrl
  gitnexus     = Test-Url "$GitNexusUrl/api/repos"
  hub          = Test-Url $HubUrl
  urls         = [ordered]@{
    hub          = $HubUrl
    hindsightUi  = $HindsightUi
    control      = $ControlUrl
    hindsightApi = $HindsightApi
    gitnexus     = $GitNexusUrl
  }
}
$report | ConvertTo-Json -Depth 5

if ($Open -and (Test-Url $HubUrl)) {
  Start-Process $HubUrl
} elseif ($Open -and (Test-Url $HindsightUi)) {
  Start-Process $HindsightUi
}
