# SPDX-License-Identifier: MIT
# Wrap Windows Store / pip uv+uvx with GUI-subsystem shims so Windows Terminal
# does not open an empty console when Hindsight starts hindsight-api via uvx.
#
# Safe to re-run. Real binaries are kept as uv.real.exe / uvx.real.exe.
param(
    [string]$ScriptsDir = ""
)

$ErrorActionPreference = "Stop"

if (-not $ScriptsDir) {
    $cmd = Get-Command "uv.exe" -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -match "PythonSoftwareFoundation|local-packages\\Python") {
        $ScriptsDir = Split-Path -Parent $cmd.Source
    } else {
        $guess = Join-Path $env:LOCALAPPDATA "Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts"
        if (Test-Path $guess) { $ScriptsDir = $guess }
    }
}

if (-not $ScriptsDir -or -not (Test-Path $ScriptsDir)) {
    throw "Could not locate uv Scripts directory. Pass -ScriptsDir explicitly."
}

$csc = @(
    (Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"),
    (Join-Path $env:WINDIR "Microsoft.NET\Framework\v4.0.30319\csc.exe")
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $csc) { throw "csc.exe not found (need .NET Framework compiler)." }

function Install-HiddenShim {
    param([string]$Name)
    $target = Join-Path $ScriptsDir $Name
    $real = Join-Path $ScriptsDir ($Name -replace "\.exe$", ".real.exe")
    if (-not (Test-Path $target) -and -not (Test-Path $real)) {
        Write-Warning "skip missing $Name"
        return
    }
    if ((Test-Path $target) -and -not (Test-Path $real)) {
        # Don't move an already-tiny shim over the real binary.
        if ((Get-Item $target).Length -lt 100KB) {
            throw "$target looks like a shim already, but $real is missing. Restore uv from pip/uv first."
        }
        Move-Item -LiteralPath $target -Destination $real -Force
        Write-Output "moved $Name -> $(Split-Path $real -Leaf)"
    } elseif (Test-Path $target) {
        Remove-Item -LiteralPath $target -Force
    }

    $escaped = $real.Replace("\", "\\")
    $prog = @"
using System;
using System.Diagnostics;
using System.Text;
class Program {
  static int Main(string[] args) {
    var psi = new ProcessStartInfo();
    psi.FileName = "$escaped";
    var sb = new StringBuilder();
    for (int i = 0; i < args.Length; i++) {
      if (i > 0) sb.Append(' ');
      var a = args[i] ?? "";
      if (a.Length == 0) { sb.Append("\"\""); continue; }
      bool quote = a.IndexOfAny(new char[]{' ', '\t', '"'}) >= 0;
      if (quote) sb.Append('"');
      sb.Append(a.Replace("\"", "\\\""));
      if (quote) sb.Append('"');
    }
    psi.Arguments = sb.ToString();
    psi.UseShellExecute = false;
    psi.CreateNoWindow = true;
    using (var p = Process.Start(psi)) {
      if (p == null) return 1;
      p.WaitForExit();
      return p.ExitCode;
    }
  }
}
"@
    $tmp = Join-Path $env:TEMP "hindsight-uv-shim-$Name.cs"
    Set-Content -Path $tmp -Value $prog -Encoding ASCII
    & $csc /nologo /target:winexe /optimize+ /out:$target $tmp
    if ($LASTEXITCODE -ne 0) { throw "csc failed for $Name" }
    Write-Output "shimmed $target -> $real"
}

Install-HiddenShim "uv.exe"
Install-HiddenShim "uvx.exe"
Write-Output "Done. Re-run after upgrading uv if the console window returns."
