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

On this branch both example configs set `autoRecall` and `autoRetain` to **false**, so hooks do not mine transcripts. That job belongs to Continual Learning (`AGENTS.md`).

| File | Automatic retain | Notes |
|------|------------------|-------|
| `cursor.json` | off | Default example for this branch |
| `cursor.full-retain.json` | off | `retainEveryNTurns: 1` is unused while `autoRetain` is false. On `main` this file is the every-turn profile. |

`install.ps1 -WriteCursorJson` copies **`cursor.json`**. Local API still does **not** mean the configured LLM never sees session text — see PRIVACY.md. Explicit MCP `retain` can still store text you ask the agent to keep.

## No overlap with Continual Learning

`hooks.json` has `sessionStart` only. That command runs `session-start-with-ensure.py`, which starts the local daemon and does not call `session_start.py`.

There is no `stop` hook and no `retain.py`. Continual Learning already mines transcripts into `AGENTS.md` (`Learned User Preferences`, `Learned Workspace Facts`).

`cursor.json` and `cursor.full-retain.json` set `autoRecall` and `autoRetain` to `false` on this branch. `retainEveryNTurns` in the full-retain file does nothing while `autoRetain` is false. Automatic transcript retain is the `main` release (v1.1.0). Do not turn the flags back on while the Continual Learning plugin is installed. Explicit MCP `recall` / `retain` / `reflect` stay available.

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
| `cursor.full-retain.json` | optional file from `main`; on this branch `autoRetain` is false |
