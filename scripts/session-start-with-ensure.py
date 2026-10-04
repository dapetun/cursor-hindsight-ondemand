# SPDX-License-Identifier: MIT
"""Cursor sessionStart wrapper: ensure local Hindsight daemon, then recall.

Keeps the Hindsight HTTP API on http://127.0.0.1:9077 only. Never points at cloud.
Local API does not mean LLM providers never see session text — see docs/PRIVACY.md.
"""
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
HINDSIGHT_DIR = HOME / ".hindsight"
ENSURE_PS1 = HINDSIGHT_DIR / "ensure-daemon.ps1"
SESSION_START = (
    HINDSIGHT_DIR
    / "plugin-host"
    / ".cursor-plugin"
    / "hindsight-memory"
    / "scripts"
    / "session_start.py"
)

# Leave headroom under hooks.json sessionStart timeout (180s).
ENSURE_WAIT_SECONDS = 150


def _augment_path(env: dict) -> dict:
    extras = [
        str(HOME / ".local" / "bin"),
        str(Path(os.environ.get("APPDATA", "")) / "npm"),
    ]
    prefix = os.pathsep.join(p for p in extras if p and p != str(Path("")))
    env = dict(env)
    env["PATH"] = prefix + os.pathsep + env.get("PATH", "")
    return env


def main() -> int:
    stdin_data = sys.stdin.buffer.read()

    if not ENSURE_PS1.is_file():
        sys.stderr.write(f"hindsight: missing {ENSURE_PS1}\n")
        return 1

    ensure = subprocess.run(
        [
            "powershell.exe",
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(ENSURE_PS1),
            "-WaitSeconds",
            str(ENSURE_WAIT_SECONDS),
        ],
        capture_output=True,
        text=True,
    )
    if ensure.stdout:
        sys.stderr.write(ensure.stdout)
    if ensure.stderr:
        sys.stderr.write(ensure.stderr)

    # Even if ensure timed out, still run session_start so later turns can work
    # once the daemon finishes warming; recall may be empty this turn.
    if not SESSION_START.is_file():
        sys.stderr.write(
            f"hindsight: missing plugin script {SESSION_START}\n"
            "Install the official Hindsight Cursor integration first.\n"
        )
        return ensure.returncode or 1

    result = subprocess.run(
        [sys.executable, str(SESSION_START)],
        input=stdin_data,
        env=_augment_path(os.environ),
    )
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
