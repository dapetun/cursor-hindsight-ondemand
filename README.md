# On-demand local Hindsight memory for Cursor (Windows)

**Last updated:** 2026-10-04 · **License:** [MIT](LICENSE) · **OS:** Windows · **Release:** [v1.1.0](https://github.com/dapetun/cursor-hindsight-ondemand/releases/tag/v1.1.0)

**Stack partner (public MIT):** [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) — [README](https://github.com/dapetun/cursor-model-orchestrator#readme) · [v0.1.0](https://github.com/dapetun/cursor-model-orchestrator/releases/tag/v0.1.0) · [stack.md](https://github.com/dapetun/cursor-model-orchestrator/blob/main/docs/integrations/stack.md)

**cursor-hindsight-ondemand** starts the local [Hindsight](https://github.com/vectorize-io/hindsight) memory daemon only when Cursor agent work needs it — not when Windows boots. It wires Cursor `sessionStart` hooks and MCP so recall/retain stay on `127.0.0.1`, without leaving `hindsight-embed` in Startup all day.

> **In short:** If you use Hindsight with Cursor on Windows and hate an always-on daemon, install these wrappers. They check `/health`, start the daemon when an agent chat or MCP tools need it, wait until it is ready, then run the official recall path — still bound to localhost so a cold start does not fall through to Hindsight Cloud.

## What is cursor-hindsight-ondemand?

cursor-hindsight-ondemand is a small set of Windows wrappers that start local Hindsight (`hindsight-embed`) on demand for Cursor. It runs ensure → wait → official `sessionStart` / MCP paths against `http://127.0.0.1:9077`, so agent memory stays local and idle RAM stays free when Cursor is not using memory tools.

It does **not** replace Hindsight, Cursor, or a model router. Pair with [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) **stack** when you also want cost-aware model recommendations plus soft Hindsight retain.

## Contents

- [Who this is for](#who-this-is-for)
- [What you get](#what-you-get)
- [Memory & Graphs dashboards](#memory--graphs-dashboards)
- [How it works](#how-it-works)
- [Privacy and data](#privacy-and-data)
- [Install](#install)
- [Used with Cursor Model Orchestrator (stack profile)](#used-with-cursor-model-orchestrator-stack-profile)
- [FAQ](#faq)
- [Related projects](#related-projects)
- [Contributing](#contributing)
- [License](#license)
- [Русская версия](#локальная-память-hindsight-для-cursor-по-требованию-windows)

## Who this is for

- Cursor users who want **cross-chat agent memory** via local Hindsight
- People who previously put `hindsight-embed` in **Windows Startup** and want that gone
- Setups that must stay on **`http://127.0.0.1:9077`** (no silent cloud API)
- Orchestrator **stack** users who need the Hindsight MCP lifecycle this skill soft-depends on

### When not to use this

| Situation | Prefer instead |
|-----------|----------------|
| You only want model routing (`/eco`, `/max`, `[route]`) | [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) **core** profile |
| You need a code-intelligence graph / impact analysis | Upstream GitNexus (not this repo) |
| You are fine with Hindsight in Windows Startup 24/7 | Official Hindsight install alone |
| You want macOS or Linux wrappers | Out of scope here (Windows only) |

## What you get

| Piece | Role |
|--------|------|
| `ensure-daemon.ps1` | Idempotent health check + local start |
| `session-start-with-ensure.py` | Cursor `sessionStart` → ensure → official recall |
| `mcp-launch.mjs` | **Preferred** Cursor MCP entry (`node`): ensure → `mcp-remote` → local Hindsight (hides console windows) |
| `mcp-launch.ps1` | Legacy PowerShell launcher; thin wrapper that calls `mcp-launch.mjs` |
| `install.ps1` | Copies wrappers into `~/.hindsight`, installs dashboard scripts + skill `memory-graph-dashboards` (writes `node …/mcp-launch.mjs` when `-WriteMcp`) |
| `examples/` | Sample `hooks.json`, `mcp.json` (uses `mcp-launch.mjs`), lean/full `cursor.json` |
| `dashboard/` | Local hub + start/stop scripts for official Hindsight UI + GitNexus web |
| `.cursor/skills/memory-graph-dashboards` | Cursor skill: open/stop dashboards **only when asked** |

This repository is glue only. You still install Hindsight, Cursor, and (optionally) GitNexus yourself. It does not redistribute those products.

## Memory & Graphs dashboards

Optional browser layer on top of the same local stack Cursor already uses. There is no official Hindsight↔GitNexus product merge — this repo ships a thin **hub** that shows status and deep-links into both official UIs.

| Surface | URL | What it is |
|---------|-----|------------|
| **Hub** | `http://127.0.0.1:8765` | Status, repo list, one-click links |
| **Hindsight Memory UI** | `http://127.0.0.1:19077` | Memories, constellation, mental models |
| **Hindsight Control** | `http://127.0.0.1:7878` | Daemon supervisor / wizard |
| **GitNexus Web** | `http://127.0.0.1:4747` | Per-repo code graphs (`gitnexus serve`) |
| **Hindsight API** | `http://127.0.0.1:9077` | MCP / health (kept for Cursor; not stopped by default) |

**Start (on demand — not at install, not at Windows login):**

```powershell
powershell -NoProfile -File $env:USERPROFILE\.hindsight\dashboard\start-dashboards.ps1 -Open
```

Or ask the Cursor agent with skill **`memory-graph-dashboards`** (“open memory/graph dashboards”).

**Stop UIs** (leaves the memory API running for MCP):

```powershell
powershell -NoProfile -File $env:USERPROFILE\.hindsight\dashboard\stop-dashboards.ps1
```

Add `-AlsoApi` only if you also want the Hindsight daemon stopped. Details: [dashboard/README.md](dashboard/README.md) · skill: [SKILL.md](.cursor/skills/memory-graph-dashboards/SKILL.md).

## How it works

1. **Agent session** — On `sessionStart`, the wrapper probes `http://127.0.0.1:9077/health`. If the daemon is down, it starts `hindsight-embed` for the `cursor` profile, waits up to ~150 seconds, then runs Hindsight `session_start.py`.
2. **MCP tools** — The same ensure step runs before a stdio proxy to `http://127.0.0.1:9077/mcp/cursor/`.
3. **Local only** — Keep `"hindsightApiUrl": "http://127.0.0.1:9077"` in `~/.hindsight/cursor.json` so a down daemon does not switch to the hosted API.

### Cold start timing

After idle, first readiness is typically **40–120 seconds** (models + DB). Set the Cursor `sessionStart` hook timeout to **180** so the first chat can wait. Later ensures usually finish in under a second if the process is already healthy.

## Privacy and data

**Not legal advice** — engineering disclosure. Full note: [docs/PRIVACY.md](docs/PRIVACY.md) · checklist: [docs/COMPLIANCE.md](docs/COMPLIANCE.md) · vuln reports: [SECURITY.md](SECURITY.md).

| Layer | What this repo does |
|-------|---------------------|
| Hindsight HTTP / MCP API | Stays on `127.0.0.1:9077`. `ensure-daemon.ps1` **refuses** non-loopback `-BaseUrl` unless you pass `-AllowNonLocal` (discouraged). |
| Session retain / recall | Runs via upstream Hindsight plugin scripts on **your** disk when hooks are enabled. |
| LLM used by `hindsight-embed` | Configured in `start-daemon.ps1` / `cursor.json` (`llmProvider` / `llmModel`). **May send content to that provider** even when the memory API is local. |
| Cursor IDE | Separate proprietary product with its own privacy terms. |

**Local memory API ≠ “nothing leaves the machine.”**

Example `examples/cursor.json` uses `retainEveryNTurns: 5` (leaner). For every-turn capture use `examples/cursor.full-retain.json`. Wipe guidance is in PRIVACY.md.

### Compared to Windows Startup

| Approach | When the daemon runs | RAM when idle | Cloud risk if misconfigured |
|----------|----------------------|---------------|-----------------------------|
| Startup shortcut / logon script | From Windows login | Always on | Low if URL is local |
| **This repo (on-demand)** | When Cursor agent/MCP needs memory | Off between sessions | Low if `hindsightApiUrl` stays `127.0.0.1:9077` |
| Hosted / non-local API URL | Depends on product | N/A | Memory can leave the machine |

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
3. Reload Cursor so hooks, MCP, and skills reload.
4. Dashboards stay off until you run `start-dashboards.ps1 -Open` or use skill `memory-graph-dashboards`.

Manual path: copy `scripts/*` into `~/.hindsight` and merge `examples/` into `~/.cursor` / `~/.hindsight` as needed. `install.ps1` also copies `dashboard/` → `~/.hindsight/dashboard` and the skill into `~/.cursor/skills` (+ `~/.agents/skills`).

### Empty console titled `uv.exe` (Windows Terminal)

Hindsight starts `hindsight-api` through `uvx`/`uv`. On Windows 11 those are console apps, so Terminal may open an empty window. Fix:

```powershell
.\scripts\install-uv-no-console-shims.ps1
```

That keeps the real binaries as `uv.real.exe` / `uvx.real.exe` and wraps them so they start with no window. Re-run after upgrading `uv` if the window comes back.

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

### Do I need cursor-model-orchestrator?

**No** for memory-only (this repo alone). **Yes (stack profile)** if you want lean route retain from the router skill via Hindsight MCP (`hindsight`) — install orchestrator with `-Profile stack`, then this repo. Orchestrator [core](https://github.com/dapetun/cursor-model-orchestrator) works without this repo.

### How do I stop Hindsight from starting at Windows login?

Install this repo’s wrappers, remove any `Startup` shortcut or logon task that launches `hindsight-embed`, then reload Cursor so `sessionStart` / MCP use `ensure-daemon` instead.

### Will memory go to the cloud?

The **Hindsight HTTP API** stays local if `hindsightApiUrl` is `http://127.0.0.1:9077` and you do not pass `-AllowNonLocal` to ensure. That does **not** guarantee that Cursor or the LLM configured for `hindsight-embed` never receive session text. See [docs/PRIVACY.md](docs/PRIVACY.md).

### What MCP server name should Cursor Model Orchestrator use?

Use **`hindsight`**. That is the name in `examples/mcp.json` and the value orchestrator stack reads as `hindsight.mcp_server`.

### Does it work on macOS or Linux?

The scripts target Windows PowerShell and `npx.cmd`. Ports to other OS are out of scope for now.

### Why is the first chat slow after idle?

Cold start loads the embed stack (typically 40–120 seconds). Warm calls are fast. Raise `sessionStart` timeout to 180 seconds for the first agent session after idle.

### Is GitNexus included?

The **GitNexus product** is not vendored here — install it separately for MCP / `gitnexus analyze`. This repo’s optional **dashboard hub** can start local `gitnexus serve` and link its web UI when GitNexus is already installed.

### Do dashboards start automatically?

No. `install.ps1` only copies scripts and the skill. UIs start when you run `start-dashboards.ps1` / ask the agent with skill `memory-graph-dashboards`.

## Related projects

| Project | Role |
|---------|------|
| [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight) | Upstream local memory product (`hindsight-embed`) |
| [dapetun/cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) | Cost-aware Cursor model routing; **stack** soft-deps on this repo |
| [GitNexus](https://github.com/abhigyanpatwari/GitNexus) | Optional code intelligence (not vendored here) |

## Repository layout

```text
scripts/     ensure-daemon, start-daemon, mcp-launch.mjs (+ legacy .ps1), session-start, uv console shims
dashboard/   hub UI + hub-server + start/stop dashboards
.cursor/skills/memory-graph-dashboards/   Cursor skill (installed to ~/.cursor/skills)
examples/    sample Cursor / Hindsight JSON (+ lean vs full-retain)
docs/        INTEGRATIONS, PRIVACY, COMPLIANCE
install.ps1  installer (wrappers + dashboard + skill)
llms.txt     short summary for AI tools
SECURITY.md  vulnerability reporting
CONTRIBUTING.md / DCO
LICENSE      MIT
NOTICE       third-party attributions
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Commits need a DCO sign-off (`git commit -s`). Inbound = outbound MIT; no CLA.

## License

MIT — see [LICENSE](LICENSE). Third-party software you install separately is listed in [NOTICE](NOTICE).

---

# Локальная память Hindsight для Cursor по требованию (Windows)

**Обновлено:** 2026-10-04 · **Лицензия:** [MIT](LICENSE) · **ОС:** Windows · **Релиз:** [v1.1.0](https://github.com/dapetun/cursor-hindsight-ondemand/releases/tag/v1.1.0)

**Парный проект (public MIT):** [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) — [README](https://github.com/dapetun/cursor-model-orchestrator#readme) · [v0.1.0](https://github.com/dapetun/cursor-model-orchestrator/releases/tag/v0.1.0) · [stack.md](https://github.com/dapetun/cursor-model-orchestrator/blob/main/docs/integrations/stack.md)

**cursor-hindsight-ondemand** поднимает локальный демон [Hindsight](https://github.com/vectorize-io/hindsight) только когда нужна агентская работа в Cursor — не при входе в Windows. Хуки `sessionStart` и MCP держат recall/retain на `127.0.0.1`, без постоянного `hindsight-embed` в автозагрузке.

> **Коротко:** пользуетесь Hindsight с Cursor на Windows и не хотите демон 24/7 — поставьте эти обёртки. Они проверяют `/health`, стартуют демон для агентского чата или MCP, ждут готовности и вызывают официальный recall, оставаясь на localhost.

## Что это такое?

cursor-hindsight-ondemand — обёртки Windows, которые стартуют локальный Hindsight по требованию для Cursor. Путь: ensure → ожидание → официальный `sessionStart` / MCP на `http://127.0.0.1:9077`. Память остаётся локальной; между сессиями демон не обязан держать RAM.

Это **не** замена Hindsight и **не** роутер моделей. Для роутинга + soft retain смотрите [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) профиль **stack**.

## Кому это нужно

- Нужна **память между чатами** через локальный Hindsight
- Раньше демон сидел в **автозагрузке Windows** — хотите убрать
- Важно не уехать в **облачный API** Hindsight
- Ставите orchestrator **stack** и нужен lifecycle Hindsight MCP

### Когда не нужно

| Ситуация | Лучше взять |
|----------|-------------|
| Только роутинг моделей | orchestrator профиль **core** |
| Граф кода / impact | upstream GitNexus |
| Демон в Startup устраивает | только официальный Hindsight |
| macOS / Linux | вне scope этого репо |

## Как работает

1. Хук `sessionStart` → `/health` → при необходимости старт демона → официальный `session_start.py`
2. MCP → тот же ensure → `mcp-remote` на локальный endpoint
3. В `cursor.json` оставляйте `"hindsightApiUrl": "http://127.0.0.1:9077"`

Холодный старт обычно **40–120 с**; таймаут хука — **180**.

## Конфиденциальность и данные

**Не юридическая консультация.** Подробно: [docs/PRIVACY.md](docs/PRIVACY.md) · чеклист: [docs/COMPLIANCE.md](docs/COMPLIANCE.md) · уязвимости: [SECURITY.md](SECURITY.md).

- HTTP/MCP API памяти — только `127.0.0.1:9077`; нелокальный `BaseUrl` без `-AllowNonLocal` отклоняется.
- Локальный API **не** означает, что LLM (Hindsight embed / Cursor) никогда не увидит текст сессии.
- Пример `cursor.json`: `retainEveryNTurns: 5`; агрессивный вариант — `cursor.full-retain.json`.

## Установка

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
.\install.ps1
.\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson   # опционально
```

Уберите ярлык из Startup, проверьте локальный URL, перезагрузите Cursor. `install.ps1` также ставит `~/.hindsight/dashboard` и skill `memory-graph-dashboards`.

## Dashboards: память и графы

Опциональный браузерный слой поверх официальных UI (отдельного merge продуктов нет — только тонкий hub):

| Поверхность | URL |
|-------------|-----|
| Hub | `http://127.0.0.1:8765` |
| Hindsight Memory UI | `http://127.0.0.1:19077` |
| Control Center | `http://127.0.0.1:7878` |
| GitNexus Web | `http://127.0.0.1:4747` |
| Hindsight API | `http://127.0.0.1:9077` (для Cursor MCP; стоп UI его не гасит) |

```powershell
powershell -NoProfile -File $env:USERPROFILE\.hindsight\dashboard\start-dashboards.ps1 -Open
powershell -NoProfile -File $env:USERPROFILE\.hindsight\dashboard\stop-dashboards.ps1
```

Или skill **`memory-graph-dashboards`** в Cursor. Автостарта при установке нет. Подробнее: [dashboard/README.md](dashboard/README.md).

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

### Это замена Hindsight?

Нет. Только старт по требованию и вызов официальных скриптов.

### Нужен ли cursor-model-orchestrator?

**Нет** для только памяти (этот репо). **Да (профиль stack)**, если роутер должен писать lean-логи через MCP `hindsight` — сначала orchestrator `-Profile stack`, затем этот `install.ps1`. Профиль [core](https://github.com/dapetun/cursor-model-orchestrator) работает без этого репо.

### Как убрать Hindsight из автозагрузки Windows?

Поставьте обёртки из этого репо, удалите ярлык/задачу Startup для `hindsight-embed`, перезагрузите Cursor.

### Уйдёт ли память в облако?

API Hindsight остаётся локальным при `hindsightApiUrl` = `http://127.0.0.1:9077` и без `-AllowNonLocal`. Это **не** гарантия, что Cursor или LLM для embed не получают текст сессии. См. [docs/PRIVACY.md](docs/PRIVACY.md).

### Какое имя MCP-сервера ждёт orchestrator stack?

**`hindsight`** — как в `examples/mcp.json`.

### macOS или Linux?

Сейчас только Windows.

### Почему первый чат после простоя медленный?

Холодный старт embed-стека (обычно 40–120 с). Таймаут `sessionStart` — 180.

### GitNexus входит в репо?

Сам продукт — нет (ставьте upstream). Опциональный **hub** умеет поднять локальный `gitnexus serve` и дать ссылку на Web UI, если GitNexus уже установлен.

### Dashboards стартуют сами?

Нет. Только по `start-dashboards.ps1` / skill `memory-graph-dashboards`.

## Связанные проекты

| Проект | Роль |
|--------|------|
| [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight) | Upstream-память |
| [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) | Роутинг моделей; stack soft-deps на этот репо |
| [GitNexus](https://github.com/abhigyanpatwari/GitNexus) | Опциональный code intelligence |

## Участие

[CONTRIBUTING.md](CONTRIBUTING.md) — DCO (`git commit -s`), inbound = outbound MIT.

## Лицензия

MIT — [LICENSE](LICENSE), стороннее ПО — [NOTICE](NOTICE).
