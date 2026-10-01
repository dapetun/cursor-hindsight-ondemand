# Cursor MCP launcher: ensure local Hindsight daemon, then stdio-proxy to it.
$ErrorActionPreference = "Stop"

$userLocalBin = Join-Path $env:USERPROFILE ".local\bin"
$npmRoaming = Join-Path $env:APPDATA "npm"
$nodeDir = Join-Path ${env:ProgramFiles} "nodejs"
$env:PATH = (@($userLocalBin, $npmRoaming, $nodeDir, $env:PATH) -join ";")

$ensure = Join-Path $PSScriptRoot "ensure-daemon.ps1"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ensure -WaitSeconds 150
if ($LASTEXITCODE -ne 0) {
    Write-Error "hindsight MCP: local daemon not ready on 127.0.0.1:9077"
    exit 1
}

$mcpUrl = "http://127.0.0.1:9077/mcp/cursor/"
$npx = Get-Command "npx.cmd" -ErrorAction SilentlyContinue
if (-not $npx) { $npx = Get-Command "npx" -ErrorAction SilentlyContinue }
if (-not $npx) { throw "npx not found. Install Node.js to run mcp-remote." }

& $npx.Source -y mcp-remote@0.14.3 $mcpUrl
exit $LASTEXITCODE
