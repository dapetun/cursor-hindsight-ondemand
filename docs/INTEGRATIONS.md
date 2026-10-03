# Integrations boundary

This repository is **glue for on-demand local Hindsight** on Windows Cursor. It does not ship a model router or a code-intelligence graph.

## What is in scope

| Piece | Role |
|--------|------|
| `ensure-daemon.ps1` / `start-daemon.ps1` | Health check + local `hindsight-embed` start |
| `session-start-with-ensure.py` | Cursor `sessionStart` → ensure → official recall |
| `mcp-launch.ps1` | Ensure → `mcp-remote` → local Hindsight MCP |
| `install.ps1` + `examples/` | Install wrappers; sample hooks / MCP / `cursor.json` |

Local API must stay at **`http://127.0.0.1:9077`** (`hindsightApiUrl` in `~/.hindsight/cursor.json`).

## What is out of scope

| Concern | Where it lives |
|---------|----------------|
| Model routing skill, `routes.yaml` / `budget.yaml` / classifier | [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) |
| GitNexus MCP, impact / detect_changes, code graph | Upstream GitNexus (not vendored here) |
| Official Hindsight product / `hindsight-embed` binary | [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight) |

This repo does **not** duplicate the `model-orchestrator` skill.

## Pairing with Cursor Model Orchestrator (stack)

Orchestrator install profiles:

- **`core`** — routing only; no Hindsight retain required.
- **`stack`** — same skill + soft deps: retain when Hindsight MCP is up; optional GitNexus hints.

**Canonical names (aligned with orchestrator `docs/integrations/stack.md` and `config/integrations.stack.yaml`):**

| Setting | Value |
|---------|--------|
| MCP server name | `hindsight` |
| Local API URL | `http://127.0.0.1:9077` |

**Suggested stack install order**

1. Orchestrator: `pwsh -File .\scripts\install_skill.ps1 -Profile stack`
2. This repo: `.\install.ps1` (optionally `-WriteHooks -WriteMcp -WriteCursorJson`)
3. GitNexus (optional), separately from upstream

If retain MCP is missing, orchestrator stack skips logging and continues routing — that is intentional soft-dep behavior, not a failure of this repo.
