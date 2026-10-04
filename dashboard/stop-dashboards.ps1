#Requires -Version 5.1
# SPDX-License-Identifier: MIT
<#
.SYNOPSIS
  Stop Memory UI, Control Center, GitNexus serve, and the Memory & Graphs hub.
  Leaves Hindsight API running (used by Cursor MCP) unless -AlsoApi.
#>
param(
  [switch]$AlsoApi,
  [string]$Profile = "cursor"
)

$ErrorActionPreference = "SilentlyContinue"

$userLocalBin = Join-Path $env:USERPROFILE ".local\bin"
$npmRoaming = Join-Path $env:APPDATA "npm"
$env:PATH = (@($userLocalBin, $npmRoaming, $env:PATH) -join ";")

function Stop-ListenersOnPort([int]$Port) {
  $conns = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
  foreach ($c in $conns) {
    $procId = $c.OwningProcess
    if ($procId -and $procId -gt 0) {
      Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    }
  }
}

$embed = Get-Command "hindsight-embed.exe" -ErrorAction SilentlyContinue
if (-not $embed) { $embed = Get-Command "hindsight-embed" -ErrorAction SilentlyContinue }

if ($embed) {
  & $embed.Source -p $Profile ui stop 2>$null | Out-Null
  & $embed.Source -p $Profile control stop 2>$null | Out-Null
}

# Hub + GitNexus (and UI/control if CLI stop missed them)
Stop-ListenersOnPort 8765
Stop-ListenersOnPort 19077
Stop-ListenersOnPort 7878
Stop-ListenersOnPort 4747

if ($AlsoApi) {
  if ($embed) {
    & $embed.Source -p $Profile daemon stop 2>$null | Out-Null
  }
  Stop-ListenersOnPort 9077
}

Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
  Where-Object {
    $_.CommandLine -and (
      $_.CommandLine -match 'hub-server\.mjs' -or
      ($_.CommandLine -match 'gitnexus' -and $_.CommandLine -match '\bserve\b')
    )
  } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

@{
  stopped = @{
    hub         = $true
    hindsightUi = $true
    control     = $true
    gitnexus    = $true
    api         = [bool]$AlsoApi
  }
} | ConvertTo-Json
