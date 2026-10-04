# Memory & Graphs dashboards

Local hub that links official **Hindsight** Memory UI / Control Center with **GitNexus** web UI.

## Ports (loopback only)

| Service | Port |
|---------|------|
| Hub | 8765 |
| Hindsight API | 9077 |
| Hindsight Memory UI | 19077 |
| Hindsight Control | 7878 |
| GitNexus serve | 4747 |

## Commands

```powershell
# Start (no browser)
.\dashboard\start-dashboards.ps1

# Start + open hub
.\dashboard\start-dashboards.ps1 -Open

# Stop UIs (keep API)
.\dashboard\stop-dashboards.ps1

# Stop UIs + API
.\dashboard\stop-dashboards.ps1 -AlsoApi
```

After `.\install.ps1`, the same scripts live in `%USERPROFILE%\.hindsight\dashboard\`.

## Skill

Agent skill: `memory-graph-dashboards` — starts/opens only when the user asks.

## Integration model

Official products stay separate. The hub is a thin localhost page + `/api/status` that:

1. Shows green/red status for each service
2. Lists GitNexus registry / `/api/repos` projects
3. Deep-links into Memory UI and Graph UI

No second memory engine and no reimplementation of either product.

## Notes

- Memory UI is started via `npx @vectorize-io/hindsight-control-plane` (same package `hindsight-embed ui start` uses). Cold first start can take up to ~2 minutes.
- Stopping dashboards leaves Hindsight API `:9077` running for Cursor MCP unless `-AlsoApi`.
- Cursor skill: `memory-graph-dashboards` — start/open only when the user asks.
