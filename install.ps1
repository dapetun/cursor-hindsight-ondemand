# Install on-demand Hindsight wrappers for Cursor (Windows).
# Usage (from repo root):
#   .\install.ps1
#   .\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson
param(
    [switch]$WriteHooks,
    [switch]$WriteMcp,
    [switch]$WriteCursorJson
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
    "session-start-with-ensure.py"
)) {
    Copy-Item -LiteralPath (Join-Path $scriptsSrc $name) -Destination (Join-Path $dest $name) -Force
    Write-Output "installed $(Join-Path $dest $name)"
}

$examples = Join-Path $root "examples"
$cursorDir = Join-Path $env:USERPROFILE ".cursor"
New-Item -ItemType Directory -Force -Path $cursorDir | Out-Null

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
        Write-Warning "hooks.json already exists — writing example beside it"
        $hooksPath = Join-Path $cursorDir "hooks.hindsight-ondemand.example.json"
    }
    ($hooksObj | ConvertTo-Json -Depth 8) | Set-Content -Path $hooksPath -Encoding utf8
    Write-Output "wrote $hooksPath"
}

if ($WriteMcp) {
    $mcpPath = Join-Path $cursorDir "mcp.json"
    $launch = Join-Path $dest "mcp-launch.ps1"
    $mcpObj = [ordered]@{
        mcpServers = [ordered]@{
            hindsight = [ordered]@{
                command = "powershell.exe"
                args = @(
                    "-NoProfile",
                    "-ExecutionPolicy",
                    "Bypass",
                    "-File",
                    $launch
                )
            }
        }
    }
    if (Test-Path $mcpPath) {
        Write-Warning "mcp.json already exists — writing example beside it"
        $mcpPath = Join-Path $cursorDir "mcp.hindsight-ondemand.example.json"
    }
    ($mcpObj | ConvertTo-Json -Depth 8) | Set-Content -Path $mcpPath -Encoding utf8
    Write-Output "wrote $mcpPath"
}

if ($WriteCursorJson) {
    $cfgPath = Join-Path $dest "cursor.json"
    if (Test-Path $cfgPath) {
        Write-Warning "cursor.json already exists — leaving untouched: $cfgPath"
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
Write-Output "  4. Reload Cursor so hooks / MCP pick up the new commands."
