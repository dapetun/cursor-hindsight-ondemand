# Start the local Hindsight embed daemon for the "cursor" profile.
# Customize LLM provider/model via env before calling, or edit the defaults below.
param(
    [string]$Profile = "cursor",
    [string]$LlmProvider = $(if ($env:HINDSIGHT_API_LLM_PROVIDER) { $env:HINDSIGHT_API_LLM_PROVIDER } else { "openai-codex" }),
    [string]$LlmModel = $(if ($env:HINDSIGHT_API_LLM_MODEL) { $env:HINDSIGHT_API_LLM_MODEL } else { "gpt-5.6-terra" })
)

$ErrorActionPreference = "Stop"

$userLocalBin = Join-Path $env:USERPROFILE ".local\bin"
$npmRoaming = Join-Path $env:APPDATA "npm"
$env:PATH = (@($userLocalBin, $npmRoaming, $env:PATH) -join ";")

$env:HINDSIGHT_API_LLM_PROVIDER = $LlmProvider
$env:HINDSIGHT_API_LLM_MODEL = $LlmModel

$embed = Get-Command "hindsight-embed.exe" -ErrorAction SilentlyContinue
if (-not $embed) {
    $embed = Get-Command "hindsight-embed" -ErrorAction SilentlyContinue
}
if (-not $embed) {
    throw "hindsight-embed not found on PATH. Install Hindsight embed CLI first."
}

& $embed.Source -p $Profile daemon start
