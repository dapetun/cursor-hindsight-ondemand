---
name: memory-graph-dashboards
description: >-
  Starts and opens the local Memory & Graphs hub that links official Hindsight UI
  (memories, constellation, mental models) with GitNexus web (per-repo code graphs).
  Use when the user asks to open Hindsight UI, GitNexus UI, memory dashboard, graph
  dashboard, control center, or memory-graph-dashboards — never auto-start UIs unless asked.
---

# Memory & Graphs dashboards

Local integration hub for two official UIs already on the machine:

| Surface | URL | Role |
|---------|-----|------|
| **Hub** | `http://127.0.0.1:8765` | Status + one-click links (Cursor-dark) |
| **Hindsight Memory UI** | `http://127.0.0.1:19077` | Bank `cursor` memories / constellation |
| **Hindsight Control** | `http://127.0.0.1:7878` | Daemon supervisor / wizard |
| **GitNexus Web** | `http://127.0.0.1:4747` | Code graphs for indexed repos |
| **Hindsight API** | `http://127.0.0.1:9077` | MCP / health (kept for Cursor; not stopped by default) |

There is no official Hindsight↔GitNexus product merge. This skill uses the repo hub as the integration layer.

## Hard rules

1. **Do not start** UI/serve processes unless the user asks to open, start, show, or launch dashboards/UIs.
2. Prefer the **hub** URL as the primary entry (`8765`). Mention Memory UI and Graph UI as secondary deep links.
3. Keep bindings on **127.0.0.1** only. Never suggest cloud Hindsight URL or `0.0.0.0` for daily use.
4. Stopping dashboards must **not** stop the Hindsight API unless the user explicitly wants the daemon down (`-AlsoApi`).
5. On Windows, use the PowerShell scripts below (they hide console windows).

## Resolve script root

Prefer installed copies, then the git checkout:

1. `%USERPROFILE%\.hindsight\dashboard\start-dashboards.ps1`
2. `<repo>\dashboard\start-dashboards.ps1` when the workspace is `cursor-hindsight-ondemand`

## When user asks to open / start

Run (PowerShell, hidden-friendly):

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.hindsight\dashboard\start-dashboards.ps1" -Open
```

If the installed path is missing, use the repo path:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<repo>\dashboard\start-dashboards.ps1" -Open
```

Then report the JSON status fields and open/link:

- Hub: `http://127.0.0.1:8765`
- Memory UI: `http://127.0.0.1:19077`
- Graph UI: `http://127.0.0.1:4747`

## When user asks to stop

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.hindsight\dashboard\stop-dashboards.ps1"
```

Only add `-AlsoApi` if they explicitly want the memory daemon stopped.

## Status only (no start)

Probe with short HTTP timeouts:

- `http://127.0.0.1:8765/api/status` (hub — richest)
- else `/health` on `:9077`, root on `:19077`, `/api/repos` on `:4747`

If hub is down and user only asked for status, report offline — do not start.

## Optional flags

| Flag | Effect |
|------|--------|
| `-SkipControl` | Do not start Control Center `:7878` |
| `-SkipGitNexus` | Memory/hub only |
| `-SkipHindsightUi` | Graph/hub only |
| `-SkipHub` | Start official UIs without hub |

## Install / refresh wrappers

From the `cursor-hindsight-ondemand` repo:

```powershell
.\install.ps1
```

This copies `dashboard\` into `~/.hindsight\dashboard` and installs this skill into `~/.cursor/skills/memory-graph-dashboards` (and `~/.agents/skills` when present).

## Notes for the agent

- GitNexus MCP tools (`impact`, `detect_changes`, …) stay in Cursor; the web UI is for human browsing.
- Hindsight MCP tools (`recall`, `retain`, directives, mental models) stay in Cursor; the Memory UI is for human browsing.
- Cold Hindsight API start can take 40–120s; UI start after API is usually faster.
- If GitNexus shows no repos, remind the user to run `gitnexus analyze` in the project (do not invent indexes).
