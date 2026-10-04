# SPDX-License-Identifier: MIT
# Start the local Hindsight embed daemon for the "cursor" profile without a console window.
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

function Start-NoWindow {
    param(
        [Parameter(Mandatory = $true)][string]$FileName,
        [string]$Arguments = "",
        [switch]$Wait
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FileName
    $psi.Arguments = $Arguments
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.WorkingDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { $env:USERPROFILE }

    # Ensure child sees the same PATH / LLM env (StringDictionary for PS 5.1).
    $psi.EnvironmentVariables["PATH"] = $env:PATH
    $psi.EnvironmentVariables["HINDSIGHT_API_LLM_PROVIDER"] = $env:HINDSIGHT_API_LLM_PROVIDER
    $psi.EnvironmentVariables["HINDSIGHT_API_LLM_MODEL"] = $env:HINDSIGHT_API_LLM_MODEL
    if ($env:USERPROFILE) { $psi.EnvironmentVariables["USERPROFILE"] = $env:USERPROFILE }
    if ($env:HOME) { $psi.EnvironmentVariables["HOME"] = $env:HOME }
    if ($env:APPDATA) { $psi.EnvironmentVariables["APPDATA"] = $env:APPDATA }
    if ($env:LOCALAPPDATA) { $psi.EnvironmentVariables["LOCALAPPDATA"] = $env:LOCALAPPDATA }

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    [void]$proc.Start()
    if ($Wait) {
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        if ($stdout) { Write-Output $stdout.TrimEnd() }
        if ($stderr) { Write-Output $stderr.TrimEnd() }
        return $proc.ExitCode
    }
    return 0
}

Write-Output ("hindsight: starting embed profile={0} (no console window)" -f $Profile)
$exitCode = Start-NoWindow -FileName $embed.Source -Arguments ("-p {0} daemon start" -f $Profile) -Wait
if ($exitCode -ne 0) {
    throw "hindsight-embed daemon start failed (exit $exitCode)"
}
