# SPDX-License-Identifier: MIT
"""Cursor sessionStart wrapper: ensure the local Hindsight daemon is up.

Does not call official session_start.py. That script auto-recalls memories
and writes .cursor/rules/hindsight-session.mdc, which duplicates the Continual
Learning plugin (AGENTS.md: Learned User Preferences, Learned Workspace Facts).

This hook only warms http://127.0.0.1:9077 so explicit MCP tools are ready.
It never points at Hindsight Cloud.
Local API does not mean LLM providers never see session text — see docs/PRIVACY.md.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

HOME = Path.home()
HINDSIGHT_DIR = HOME / ".hindsight"
ENSURE_PS1 = HINDSIGHT_DIR / "ensure-daemon.ps1"

# Leave headroom under hooks.json sessionStart timeout (180s).
ENSURE_WAIT_SECONDS = 150


def main() -> int:
    # Drain hook stdin so Cursor is not left blocked on the pipe.
    sys.stdin.buffer.read()

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
    return ensure.returncode


if __name__ == "__main__":
    raise SystemExit(main())
