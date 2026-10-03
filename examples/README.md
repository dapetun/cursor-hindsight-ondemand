# Example Cursor / Hindsight configs

JSON has no comments — read this note before copying files into `~/.cursor` or `~/.hindsight`.

## Required local URL

Keep **`hindsightApiUrl`** as:

```json
"hindsightApiUrl": "http://127.0.0.1:9077"
```

Do not point it at a cloud Hindsight API. A cold daemon + wrong URL can fall through to hosted memory.

See `cursor.json` in this folder.

## MCP server name (orchestrator stack)

Cursor Model Orchestrator **stack** profile expects the MCP server key **`hindsight`** (orchestrator `integrations.yaml` → `hindsight.mcp_server`).

`mcp.json` in this folder already uses that name and launches **`mcp-launch.mjs`** via `node` (preferred). `mcp-launch.ps1` is legacy. Rename the MCP key only if you also change the orchestrator config.

## Placeholders

Paths use `YOU` as a stand-in for your Windows username. Prefer running `..\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson` so paths are filled from `%USERPROFILE%`.

| File | Merge into |
|------|------------|
| `hooks.json` | `~/.cursor/hooks.json` |
| `mcp.json` | `~/.cursor/mcp.json` |
| `cursor.json` | `~/.hindsight/cursor.json` |
