# SPDX-License-Identifier: MIT
# Legacy PowerShell MCP launcher (may show a console). Prefer mcp-launch.mjs via node.
$ErrorActionPreference = "Stop"

$userLocalBin = Join-Path $env:USERPROFILE ".local\bin"
$npmRoaming = Join-Path $env:APPDATA "npm"
$nodeDir = Join-Path ${env:ProgramFiles} "nodejs"
$env:PATH = (@($userLocalBin, $npmRoaming, $nodeDir, $env:PATH) -join ";")

$mjs = Join-Path $PSScriptRoot "mcp-launch.mjs"
if (Test-Path -LiteralPath $mjs) {
    $node = Get-Command "node.exe" -ErrorAction SilentlyContinue
    if (-not $node) { $node = Get-Command "node" -ErrorAction SilentlyContinue }
    if (-not $node) { throw "node not found. Install Node.js." }
    & $node.Source $mjs
    exit $LASTEXITCODE
}

$ensure = Join-Path $PSScriptRoot "ensure-daemon.ps1"
$p = Start-Process -FilePath "powershell.exe" `
    -ArgumentList @("-NoLogo", "-NoProfile", "-WindowStyle", "Hidden", "-ExecutionPolicy", "Bypass", "-File", $ensure, "-WaitSeconds", "150") `
    -Wait -PassThru -WindowStyle Hidden
if ($p.ExitCode -ne 0) {
    Write-Error "hindsight MCP: local daemon not ready on 127.0.0.1:9077"
    exit 1
}

$mcpUrl = "http://127.0.0.1:9077/mcp/cursor/"
$npx = Get-Command "npx.cmd" -ErrorAction SilentlyContinue
if (-not $npx) { $npx = Get-Command "npx" -ErrorAction SilentlyContinue }
if (-not $npx) { throw "npx not found. Install Node.js to run mcp-remote." }

& $npx.Source -y mcp-remote@0.14.3 $mcpUrl
exit $LASTEXITCODE
