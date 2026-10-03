# On-demand local Hindsight memory for Cursor (Windows)

**cursor-hindsight-ondemand** starts the local [Hindsight](https://github.com/vectorize-io/hindsight) memory daemon only when Cursor agent work needs it — not when Windows boots. It wires Cursor `sessionStart` hooks and MCP so recall/retain stay on `127.0.0.1`, without leaving `hindsight-embed` in Startup all day.

> **In short:** If you use Hindsight with Cursor on Windows and hate an always-on daemon, install these wrappers. They check `/health`, start the daemon when an agent chat or MCP tools need it, wait until it is ready, then run the official recall path — still bound to localhost so a cold start does not fall through to Hindsight Cloud.

## Who this is for

- Cursor users who want **cross-chat agent memory** via local Hindsight
- People who previously put `hindsight-embed` in **Windows Startup** and want that gone
- Setups that must stay on **`http://127.0.0.1:9077`** (no silent cloud API)

## What you get

| Piece | Role |
|--------|------|
| `ensure-daemon.ps1` | Idempotent health check + local start |
| `session-start-with-ensure.py` | Cursor `sessionStart` → ensure → official recall |
| `mcp-launch.ps1` | Ensure → `mcp-remote` → local Hindsight MCP |
| `install.ps1` | Copies wrappers into `~/.hindsight` |
| `examples/` | Sample `hooks.json`, `mcp.json`, `cursor.json` |

This repository is glue only. You still install Hindsight and Cursor yourself. It does not redistribute those products.

## How it works

1. **Agent session** — On `sessionStart`, the wrapper probes `http://127.0.0.1:9077/health`. If the daemon is down, it starts `hindsight-embed` for the `cursor` profile, waits up to ~150 seconds, then runs Hindsight `session_start.py`.
2. **MCP tools** — The same ensure step runs before a stdio proxy to `http://127.0.0.1:9077/mcp/cursor/`.
3. **Local only** — Keep `"hindsightApiUrl": "http://127.0.0.1:9077"` in `~/.hindsight/cursor.json` so a down daemon does not switch to the hosted API.

### Cold start timing

After idle, first readiness is typically **40–120 seconds** (models + DB). Set the Cursor `sessionStart` hook timeout to **180** so the first chat can wait. Later ensures usually finish in under a second if the process is already healthy.

### Compared to Windows Startup

| Approach | When the daemon runs | RAM when idle |
|----------|----------------------|---------------|
| Startup shortcut / logon script | From Windows login | Always on |
| **This repo** | When Cursor agent/MCP needs memory | Off between sessions |

## Requirements

- Windows + PowerShell
- [Cursor](https://cursor.com)
- Local Hindsight / `hindsight-embed` + official Cursor integration (`session_start.py`, `retain.py` on disk)
- Python 3 (hooks)
- Node.js + `npx` (MCP launcher via `mcp-remote`)

**Known upstream gap:** some Hindsight `init` installs omit `scripts/lib/rules_file.py`, which breaks `session_start.py` with `ModuleNotFoundError: lib.rules_file`. Copy that file from the [upstream Cursor integration](https://github.com/vectorize-io/hindsight) into the plugin `lib` folder.

## Install

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
.\install.ps1
```

Wrappers land in `%USERPROFILE%\.hindsight`. Optional example configs (existing files are not overwritten; examples are written beside them):

```powershell
.\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson
```

Then:

1. Confirm `~/.hindsight/cursor.json` uses `"hindsightApiUrl": "http://127.0.0.1:9077"`.
2. Remove any `Startup\…hindsight…` Windows autostart.
3. Reload Cursor so hooks and MCP reload.

Manual path: copy `scripts/*` into `~/.hindsight` and merge `examples/` into `~/.cursor` / `~/.hindsight` as needed.

## Used with Cursor Model Orchestrator (stack profile)

This repo is the **local Hindsight lifecycle** for Cursor (ensure-daemon / sessionStart / mcp-launch). It is **not** a model router.

The paired project [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) (MIT) ships a Cursor skill with two install profiles:

| Profile | What you get |
|--------|----------------|
| `core` | Model routing skill only (no Hindsight / GitNexus) |
| `stack` | Same skill + soft deps: Hindsight retain via **this** repo, optional GitNexus (upstream, not vendored here) |

**Stack install order**

1. **Orchestrator (stack)** — from [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator):

   ```powershell
   pwsh -File .\scripts\install_skill.ps1 -Profile stack
   ```

2. **This repo** — clone + wrappers (+ optional hooks/MCP examples):

   ```powershell
   git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
   cd cursor-hindsight-ondemand
   .\install.ps1
   .\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson   # optional
   ```

3. **GitNexus (optional)** — install separately from upstream; not part of this repository.

**Orchestrator stack expects:** MCP server name `hindsight` (see `examples/mcp.json`) and `"hindsightApiUrl": "http://127.0.0.1:9077"`. Details: [docs/INTEGRATIONS.md](docs/INTEGRATIONS.md) and orchestrator `docs/integrations/stack.md`.

## FAQ

### Does this replace Hindsight?

No. It only starts and waits for your local Hindsight daemon when Cursor needs it, then calls the official plugin scripts.

### Will memory go to the cloud?

Not if `hindsightApiUrl` stays on `127.0.0.1:9077`. That explicit local URL is the intended setup for this wrapper.

### Does it work on macOS or Linux?

The scripts target Windows PowerShell and `npx.cmd`. Ports to other OS are out of scope for now.

### Why is the first chat slow?

Cold start loads the embed stack. Warm calls are fast. Raise `sessionStart` timeout to 180 seconds for the first agent session after idle.

### Is GitNexus included?

No. This repo is only the on-demand Hindsight lifecycle for Cursor.

## Repository layout

```text
scripts/     ensure-daemon, start-daemon, mcp-launch, session-start wrapper
examples/    sample Cursor / Hindsight JSON (+ README notes)
docs/        integrations boundary (orchestrator stack, out-of-scope)
install.ps1  installer
llms.txt     short summary for AI tools
LICENSE      MIT
NOTICE       third-party attributions
```

## License

MIT — see [LICENSE](LICENSE). Third-party software you install separately is listed in [NOTICE](NOTICE).

---

# Локальная память Hindsight для Cursor по требованию (Windows)

**cursor-hindsight-ondemand** поднимает локальный демон [Hindsight](https://github.com/vectorize-io/hindsight) только когда нужна агентская работа в Cursor — не при входе в Windows. Хуки `sessionStart` и MCP держат recall/retain на `127.0.0.1`, без постоянного `hindsight-embed` в автозагрузке.

> **Коротко:** пользуетесь Hindsight с Cursor на Windows и не хотите демон 24/7 — поставьте эти обёртки. Они проверяют `/health`, стартуют демон для агентского чата или MCP, ждут готовности и вызывают официальный recall, оставаясь на localhost.

## Кому это нужно

- Нужна **память между чатами** через локальный Hindsight
- Раньше демон сидел в **автозагрузке Windows** — хотите убрать
- Важно не уехать в **облачный API** Hindsight

## Как работает

1. Хук `sessionStart` → `/health` → при необходимости старт демона → официальный `session_start.py`
2. MCP → тот же ensure → `mcp-remote` на локальный endpoint
3. В `cursor.json` оставляйте `"hindsightApiUrl": "http://127.0.0.1:9077"`

Холодный старт обычно **40–120 с**; таймаут хука — **180**.

## Установка

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
.\install.ps1
.\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson   # опционально
```

Уберите ярлык из Startup, проверьте локальный URL, перезагрузите Cursor.

## Используется с Cursor Model Orchestrator (профиль stack)

Этот репозиторий — **lifecycle локального Hindsight** для Cursor (ensure-daemon / sessionStart / mcp-launch), а **не** роутер моделей.

Парный проект [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) (MIT) ставит skill с двумя профилями:

| Профиль | Что даёт |
|--------|----------|
| `core` | Только skill роутинга моделей |
| `stack` | Тот же skill + soft-deps: Hindsight retain через **этот** репо, опционально GitNexus (upstream, не здесь) |

**Порядок установки stack**

1. **Orchestrator:** `pwsh -File .\scripts\install_skill.ps1 -Profile stack`
2. **Этот репо:** `.\install.ps1` (+ опционально `-WriteHooks -WriteMcp -WriteCursorJson`)
3. **GitNexus (опционально)** — отдельно, не входит в этот репозиторий

**Ожидания orchestrator stack:** MCP-сервер с именем `hindsight` и `"hindsightApiUrl": "http://127.0.0.1:9077"`. Подробнее: [docs/INTEGRATIONS.md](docs/INTEGRATIONS.md).

## Частые вопросы

**Это замена Hindsight?** Нет, только старт по требованию и вызов официальных скриптов.  
**Уйдёт ли память в облако?** Нет, если URL остаётся `127.0.0.1:9077`.  
**macOS/Linux?** Сейчас только Windows.  
**GitNexus?** Не входит в этот репозиторий.

## Лицензия

MIT — [LICENSE](LICENSE), стороннее ПО — [NOTICE](NOTICE).
