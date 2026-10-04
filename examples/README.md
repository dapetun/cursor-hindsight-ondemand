# Example Cursor / Hindsight configs

JSON has no comments — read this note before copying files into `~/.cursor` or `~/.hindsight`.

Privacy overview: [../docs/PRIVACY.md](../docs/PRIVACY.md) · security: [../SECURITY.md](../SECURITY.md).

## Required local URL

Keep **`hindsightApiUrl`** as:

```json
"hindsightApiUrl": "http://127.0.0.1:9077"
```

Do not point it at a cloud Hindsight API. A cold daemon + wrong URL can fall through to hosted memory. Wrappers also refuse non-loopback ensure URLs unless you explicitly pass `-AllowNonLocal` (discouraged).

## Retain defaults (data minimization)

| File | `retainEveryNTurns` | Use when |
|------|---------------------|----------|
| `cursor.json` (default example) | **5** | Typical / org-safer pacing |
| `cursor.full-retain.json` | **1** | Maximum capture (more disk + more sensitive content retained) |

`install.ps1 -WriteCursorJson` copies **`cursor.json`** (leaner retain). Local API still does **not** mean the configured LLM never sees session text — see PRIVACY.md.

## MCP server name (orchestrator stack)

Cursor Model Orchestrator **stack** profile expects the MCP server key **`hindsight`** (orchestrator `integrations.yaml` → `hindsight.mcp_server`).

`mcp.json` in this folder already uses that name and launches **`mcp-launch.mjs`** via `node` (preferred; hides console windows). `mcp-launch.ps1` is legacy and only wraps the `.mjs`. Rename the server key only if you also change the orchestrator config.

## Placeholders

Paths use `YOU` as a stand-in for your Windows username. Prefer running `..\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson` so paths are filled from `%USERPROFILE%`.

| File | Merge into |
|------|------------|
| `hooks.json` | `~/.cursor/hooks.json` |
| `mcp.json` | `~/.cursor/mcp.json` |
| `cursor.json` | `~/.hindsight/cursor.json` |
| `cursor.full-retain.json` | optional replace for aggressive retain |
