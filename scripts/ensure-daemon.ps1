# Ensure local Hindsight daemon is healthy on 127.0.0.1:9077.
# Idempotent: if already up, returns immediately. Never falls back to cloud.
param(
    [int]$WaitSeconds = 150,
    [string]$BaseUrl = "http://127.0.0.1:9077"
)

$ErrorActionPreference = "Continue"

# Prefer user-local bins without hard-coding a machine username.
$userLocalBin = Join-Path $env:USERPROFILE ".local\bin"
$npmRoaming = Join-Path $env:APPDATA "npm"
$env:PATH = (@($userLocalBin, $npmRoaming, $env:PATH) -join ";")

function Test-HindsightHealth {
    param([string]$Url, [int]$TimeoutSec = 2)
    try {
        $resp = Invoke-WebRequest -Uri "$Url/health" -UseBasicParsing -TimeoutSec $TimeoutSec
        return ($resp.StatusCode -eq 200)
    } catch {
        return $false
    }
}

if (Test-HindsightHealth -Url $BaseUrl) {
    Write-Output "hindsight: already healthy at $BaseUrl"
    exit 0
}

$lockDir = Join-Path $env:USERPROFILE ".hindsight"
$lockFile = Join-Path $lockDir "ensure-daemon.lock"
New-Item -ItemType Directory -Force -Path $lockDir | Out-Null

$lockStream = $null
try {
    $lockStream = [System.IO.File]::Open(
        $lockFile,
        [System.IO.FileMode]::OpenOrCreate,
        [System.IO.FileAccess]::ReadWrite,
        [System.IO.FileShare]::None
    )
} catch {
    Write-Output "hindsight: another ensure in progress, waiting..."
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-HindsightHealth -Url $BaseUrl) {
            Write-Output "hindsight: healthy at $BaseUrl"
            exit 0
        }
        Start-Sleep -Seconds 2
    }
    Write-Error "hindsight: timed out waiting for peer ensure ($WaitSeconds s)"
    exit 1
}

try {
    if (Test-HindsightHealth -Url $BaseUrl) {
        Write-Output "hindsight: already healthy at $BaseUrl"
        exit 0
    }

    Write-Output "hindsight: starting local daemon..."
    $starter = Join-Path $lockDir "start-daemon.ps1"
    if (-not (Test-Path -LiteralPath $starter)) {
        Write-Error "hindsight: missing $starter (run install.ps1 first)"
        exit 1
    }

    Start-Process -FilePath "powershell.exe" `
        -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $starter) `
        -WindowStyle Hidden `
        -WorkingDirectory $lockDir | Out-Null

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $deadline = (Get-Date).AddSeconds($WaitSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-HindsightHealth -Url $BaseUrl) {
            Write-Output ("hindsight: healthy at {0} after {1:N1}s" -f $BaseUrl, $sw.Elapsed.TotalSeconds)
            exit 0
        }
        Start-Sleep -Seconds 2
    }

    Write-Error ("hindsight: daemon not healthy within {0}s (waited {1:N1}s)" -f $WaitSeconds, $sw.Elapsed.TotalSeconds)
    exit 1
} finally {
    if ($null -ne $lockStream) {
        $lockStream.Close()
        $lockStream.Dispose()
    }
}
