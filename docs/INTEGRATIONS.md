# Integrations boundary

**Last updated:** 2026-10-03

**cursor-hindsight-ondemand** is glue for on-demand local Hindsight on Windows Cursor: ensure-daemon, `sessionStart`, and MCP launch against `http://127.0.0.1:9077`. It does not ship a model router or a code-intelligence graph.

Mirrored with orchestrator [docs/integrations/stack.md](https://github.com/dapetun/cursor-model-orchestrator/blob/main/docs/integrations/stack.md).

## What is in scope

| Piece | Role |
|--------|------|
| `ensure-daemon.ps1` / `start-daemon.ps1` | Health check + local `hindsight-embed` start |
| `session-start-with-ensure.py` | Cursor `sessionStart` → ensure → official recall |
| `mcp-launch.mjs` | Preferred MCP entry (`node`): ensure → `mcp-remote` → local Hindsight |
| `mcp-launch.ps1` | Legacy PowerShell launcher (calls `mcp-launch.mjs`) |
| `install.ps1` + `examples/` | Install wrappers; sample hooks / MCP / `cursor.json` |

Local API must stay at **`http://127.0.0.1:9077`** (`hindsightApiUrl` in `~/.hindsight/cursor.json`).

## What is out of scope

| Concern | Where it lives |
|---------|----------------|
| Model routing skill, `routes.yaml` / `budget.yaml` / classifier | [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) (public MIT) |
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
| Preferred MCP command | `node` + `~/.hindsight/mcp-launch.mjs` |

**Stack install order** (same as orchestrator `stack.md`)

1. Orchestrator: `pwsh -File .\scripts\install_skill.ps1 -Profile stack`
2. This repo: `.\install.ps1` (optionally `-WriteHooks -WriteMcp -WriteCursorJson`)
3. GitNexus (optional), separately from upstream

### Soft behavior

| Tool | If missing |
|------|------------|
| Hindsight MCP | Orchestrator stack skips retain; `[route]` still printed |
| GitNexus | Orchestrator skips impact hint; routing unchanged |

Missing retain MCP is intentional soft-dep behavior, not a failure of this repo.

Partner mirrors: [stack.md](https://github.com/dapetun/cursor-model-orchestrator/blob/main/docs/integrations/stack.md) · [llms.txt](https://github.com/dapetun/cursor-model-orchestrator/blob/main/llms.txt).
