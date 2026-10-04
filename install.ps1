# SPDX-License-Identifier: MIT
# Install on-demand Hindsight wrappers for Cursor (Windows).
# Usage (from repo root):
#   .\install.ps1
#   .\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson
# Privacy: docs/PRIVACY.md - local API != no LLM egress.
param(
    [switch]$WriteHooks,
    [switch]$WriteMcp,
    [switch]$WriteCursorJson,
    [switch]$SkipDashboardSkill
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$scriptsSrc = Join-Path $root "scripts"
if (-not (Test-Path (Join-Path $scriptsSrc "ensure-daemon.ps1"))) {
    throw "Missing scripts\ensure-daemon.ps1. Run install.ps1 from the repository root."
}

$dest = Join-Path $env:USERPROFILE ".hindsight"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

foreach ($name in @(
    "ensure-daemon.ps1",
    "start-daemon.ps1",
    "mcp-launch.ps1",
    "mcp-launch.mjs",
    "session-start-with-ensure.py",
    "install-uv-no-console-shims.ps1"
)) {
    Copy-Item -LiteralPath (Join-Path $scriptsSrc $name) -Destination (Join-Path $dest $name) -Force
    Write-Output "installed $(Join-Path $dest $name)"
}

# Dashboard hub + start/stop scripts (do not auto-start services)
$dashboardSrc = Join-Path $root "dashboard"
$dashboardDest = Join-Path $dest "dashboard"
if (Test-Path -LiteralPath $dashboardSrc) {
    New-Item -ItemType Directory -Force -Path $dashboardDest | Out-Null
    # Overwrite in place (hub/server may lock the folder; avoid full Remove-Item).
    $rc = & robocopy $dashboardSrc $dashboardDest /E /IS /IT /NFL /NDL /NJH /NJS /nc /ns /np
    $code = $LASTEXITCODE
    if ($code -ge 8) {
        throw "robocopy dashboard failed with exit $code"
    }
    Write-Output "installed $dashboardDest"
}

$examples = Join-Path $root "examples"
$cursorDir = Join-Path $env:USERPROFILE ".cursor"
New-Item -ItemType Directory -Force -Path $cursorDir | Out-Null

# Personal skill: open Memory + Graph UIs on demand
if (-not $SkipDashboardSkill) {
    $skillSrc = Join-Path $root ".cursor\skills\memory-graph-dashboards"
    if (Test-Path -LiteralPath $skillSrc) {
        $skillTargets = [System.Collections.Generic.List[string]]::new()
        $skillTargets.Add((Join-Path $cursorDir "skills\memory-graph-dashboards")) | Out-Null
        $agentsRoot = Join-Path $env:USERPROFILE ".agents\skills"
        New-Item -ItemType Directory -Force -Path $agentsRoot | Out-Null
        $skillTargets.Add((Join-Path $agentsRoot "memory-graph-dashboards")) | Out-Null
        foreach ($skillDest in $skillTargets) {
            $skillParent = Split-Path -Parent $skillDest
            New-Item -ItemType Directory -Force -Path $skillParent | Out-Null
            if (Test-Path -LiteralPath $skillDest) {
                Remove-Item -LiteralPath $skillDest -Recurse -Force
            }
            Copy-Item -LiteralPath $skillSrc -Destination $skillDest -Recurse -Force
            Write-Output "installed skill $skillDest"
        }
    }
}

if ($WriteHooks) {
    $hooksPath = Join-Path $cursorDir "hooks.json"
    $sessionPy = Join-Path $dest "session-start-with-ensure.py"
    $retainPy = Join-Path $dest "plugin-host\.cursor-plugin\hindsight-memory\scripts\retain.py"
    $hooksObj = [ordered]@{
        version = 1
        hooks = [ordered]@{
            sessionStart = @(
                [ordered]@{
                    command = "python `"$sessionPy`""
                    timeout = 180
                }
            )
            stop = @(
                [ordered]@{
                    command = "python `"$retainPy`""
                    timeout = 60
                }
            )
        }
    }
    if (Test-Path $hooksPath) {
        Write-Warning "hooks.json already exists - writing example beside it"
        $hooksPath = Join-Path $cursorDir "hooks.hindsight-ondemand.example.json"
    }
    ($hooksObj | ConvertTo-Json -Depth 8) | Set-Content -Path $hooksPath -Encoding utf8
    Write-Output "wrote $hooksPath"
}

if ($WriteMcp) {
    $mcpPath = Join-Path $cursorDir "mcp.json"
    $launch = Join-Path $dest "mcp-launch.mjs"
    $mcpObj = [ordered]@{
        mcpServers = [ordered]@{
            hindsight = [ordered]@{
                command = "node"
                args = @(
                    $launch
                )
            }
        }
    }
    if (Test-Path $mcpPath) {
        Write-Warning "mcp.json already exists - writing example beside it"
        $mcpPath = Join-Path $cursorDir "mcp.hindsight-ondemand.example.json"
    }
    ($mcpObj | ConvertTo-Json -Depth 8) | Set-Content -Path $mcpPath -Encoding utf8
    Write-Output "wrote $mcpPath"
}

if ($WriteCursorJson) {
    $cfgPath = Join-Path $dest "cursor.json"
    if (Test-Path $cfgPath) {
        Write-Warning "cursor.json already exists - leaving untouched: $cfgPath"
    } else {
        Copy-Item (Join-Path $examples "cursor.json") $cfgPath
        Write-Output "wrote $cfgPath (edit llmProvider / llmModel as needed)"
    }
}

Write-Output ""
Write-Output "Next:"
Write-Output "  1. Install the official Hindsight Cursor integration so plugin-host scripts exist."
Write-Output "  2. Point ~/.hindsight/cursor.json at http://127.0.0.1:9077 (never the cloud URL)."
Write-Output "  3. Remove any Windows Startup entry that starts the daemon at login."
Write-Output "  4. Reload Cursor so hooks / MCP / skills pick up the new commands."
Write-Output "  5. Read docs/PRIVACY.md - local memory API does not mean LLM calls never leave the PC."
Write-Output "  6. Prefer examples/cursor.json (retainEveryNTurns=5); full dump: cursor.full-retain.json."
Write-Output "  7. Security reports: SECURITY.md / org checklist: docs/COMPLIANCE.md"
Write-Output "  8. Dashboards (on demand, not auto-start): skill memory-graph-dashboards"
Write-Output "     or: powershell -File ~/.hindsight/dashboard/start-dashboards.ps1 -Open"
