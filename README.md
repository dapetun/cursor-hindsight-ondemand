# On-demand local Hindsight memory for Cursor (Windows)

**Last updated:** 2026-10-22 · **License:** [MIT](LICENSE) · **OS:** Windows · **Branch:** `beside-continual-learning` · **Release:** [v1.2.0-beside-continual-learning](https://github.com/dapetun/cursor-hindsight-ondemand/releases/tag/v1.2.0-beside-continual-learning). [v1.1.0](https://github.com/dapetun/cursor-hindsight-ondemand/releases/tag/v1.1.0) on `main` still includes the automatic recall/retain loop.

**Stack partner (public MIT):** [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) — [README](https://github.com/dapetun/cursor-model-orchestrator#readme) · [v0.1.0](https://github.com/dapetun/cursor-model-orchestrator/releases/tag/v0.1.0) · [stack.md](https://github.com/dapetun/cursor-model-orchestrator/blob/main/docs/integrations/stack.md)

**cursor-hindsight-ondemand** starts the local [Hindsight](https://github.com/vectorize-io/hindsight) memory daemon only when Cursor agent work needs it — not when Windows boots. On this branch, `sessionStart` only checks `/health` and starts `hindsight-embed`. Explicit MCP stays on `127.0.0.1`. The daemon is not left in Startup all day.

> **In short:** Hindsight on Windows, without a 24/7 daemon, and without a second automatic memory loop next to the Continual Learning plugin. These wrappers check `/health`, start the local daemon for MCP, and stay on localhost so a cold start does not fall through to Hindsight Cloud.

## What is cursor-hindsight-ondemand?

cursor-hindsight-ondemand is a small set of Windows wrappers that start local Hindsight (`hindsight-embed`) on demand for Cursor. It runs ensure → wait → explicit MCP against `http://127.0.0.1:9077`, so idle RAM stays free when Cursor is not using memory tools.

It does **not** replace Hindsight, Cursor, Continual Learning, or a model router. Pair with [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) **stack** when you also want cost-aware model recommendations. Orchestrator retain, when used, goes through the Hindsight MCP server. It does not go through a `stop` hook.

## Beside Continual Learning

[Continual Learning](https://github.com/cursor/plugins) already keeps ambient memory:

- a `stop` hook reads the agent transcript
- `agents-memory-updater` writes `## Learned User Preferences` and `## Learned Workspace Facts` into `AGENTS.md`
- Cursor loads that file on later turns

This branch deletes the matching Hindsight loop. Dashboards, the on-demand daemon, and explicit MCP stay.

| Continual Learning | Removed from this branch |
|--------------------|--------------------------|
| `stop` reads the transcript | no `stop` hook, no `retain.py` |
| durable prefs and workspace facts land in `AGENTS.md` | `autoRetain: false` |
| later chats see those bullets via `AGENTS.md` | no `session_start.py`, no `.cursor/rules/hindsight-session.mdc` |

`main` (release v1.1.0) still ships that automatic loop, for setups that do not use Continual Learning.

What stays here is the part Continual Learning does not do: on-demand local `hindsight-embed`, explicit MCP (`recall`, `retain`, `reflect`, directives, mental models, knowledge pages), and the Memory & Graphs hub. Use MCP when you need searchable history or structured memory, not a second copy of the `AGENTS.md` bullets.

## Contents

- [Beside Continual Learning](#beside-continual-learning)
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

- Cursor users who want **explicit local Hindsight MCP** (recall, retain, reflect, directives, mental models) while Continual Learning keeps prefs and workspace facts in `AGENTS.md`
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
| You do not use Continual Learning and want automatic transcript recall/retain | Branch `main`, release v1.1.0 |

## What you get

| Piece | Role |
|--------|------|
| `ensure-daemon.ps1` | Idempotent health check + local start |
| `session-start-with-ensure.py` | Cursor `sessionStart` → ensure daemon only. Does not call official `session_start.py` |
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

1. **Agent session** — On `sessionStart`, the wrapper probes `http://127.0.0.1:9077/health`. If the daemon is down, it starts `hindsight-embed` for the `cursor` profile and waits up to ~150 seconds. It does not recall memories into the prompt.
2. **MCP tools** — The same ensure step runs before a stdio proxy to `http://127.0.0.1:9077/mcp/cursor/`. Call `recall` / `retain` / `reflect` from the agent when you need them.
3. **Local only** — Keep `"hindsightApiUrl": "http://127.0.0.1:9077"` and `"autoRecall": false`, `"autoRetain": false` in `~/.hindsight/cursor.json`. A down daemon must not switch to the hosted API, and the official plugin scripts must no-op if something still invokes them.

### Cold start timing

After idle, first readiness is typically **40–120 seconds** (models + DB). Set the Cursor `sessionStart` hook timeout to **180** so the first chat can wait. Later ensures usually finish in under a second if the process is already healthy.

## Privacy and data

**Not legal advice** — engineering disclosure. Full note: [docs/PRIVACY.md](docs/PRIVACY.md) · checklist: [docs/COMPLIANCE.md](docs/COMPLIANCE.md) · vuln reports: [SECURITY.md](SECURITY.md).

| Layer | What this repo does |
|-------|---------------------|
| Hindsight HTTP / MCP API | Stays on `127.0.0.1:9077`. `ensure-daemon.ps1` **refuses** non-loopback `-BaseUrl` unless you pass `-AllowNonLocal` (discouraged). |
| Session retain / recall | Not run from hooks on this branch. Explicit MCP `retain` / `recall` still can store or read the local bank when you call them. |
| LLM used by `hindsight-embed` | Configured in `start-daemon.ps1` / `cursor.json` (`llmProvider` / `llmModel`). **May send content to that provider** even when the memory API is local. |
| Cursor IDE | Separate proprietary product with its own privacy terms. |

**Local memory API ≠ “nothing leaves the machine.”**

Example `examples/cursor.json` sets `autoRecall` and `autoRetain` to `false`. `examples/cursor.full-retain.json` does the same on this branch; its `retainEveryNTurns` value is unused while `autoRetain` is false. Automatic transcript retain lives on `main`. Wipe guidance is in PRIVACY.md.

### Compared to Windows Startup

| Approach | When the daemon runs | RAM when idle | Cloud risk if misconfigured |
|----------|----------------------|---------------|-----------------------------|
| Startup shortcut / logon script | From Windows login | Always on | Low if URL is local |
| **This repo (on-demand)** | When Cursor agent/MCP needs memory | Off between sessions | Low if `hindsightApiUrl` stays `127.0.0.1:9077` |
| Hosted / non-local API URL | Depends on product | N/A | Memory can leave the machine |

## Requirements

- Windows + PowerShell
- [Cursor](https://cursor.com)
- Local Hindsight / `hindsight-embed` with MCP at `http://127.0.0.1:9077/mcp/cursor/`
- Python 3 (the ensure hook)
- Node.js + `npx` (MCP launcher via `mcp-remote`)

This branch does not call `session_start.py` or `retain.py`. The upstream `rules_file.py` gap only matters on `main`, where those official hook scripts run.

## Install

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
git checkout beside-continual-learning
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
   git checkout beside-continual-learning
   .\install.ps1
   .\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson   # optional
   ```

3. **GitNexus (optional)** — install separately from upstream; not part of this repository.

**Orchestrator stack expects:** MCP server name `hindsight` (see `examples/mcp.json`) and `"hindsightApiUrl": "http://127.0.0.1:9077"`. Details: [docs/INTEGRATIONS.md](docs/INTEGRATIONS.md) and orchestrator `docs/integrations/stack.md`.

## FAQ

### Does this replace Hindsight?

No. It only starts and waits for your local Hindsight daemon. Explicit memory tools stay on the Hindsight MCP server.

### Does this replace Continual Learning?

No. Continual Learning owns incremental transcript learning into `AGENTS.md`. This branch does not write `Learned User Preferences` or `Learned Workspace Facts`, and it does not inject a parallel rules file at session start.

If the official Hindsight Cursor plugin is also enabled, disable its `sessionStart` (`session_start.py`) and `stop` (`retain.py`) hooks. Otherwise that plugin puts the removed loop back.

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
examples/    sample Cursor / Hindsight JSON (no stop/retain hook; autoRecall and autoRetain false)
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

**Обновлено:** 2026-10-22 · **Лицензия:** [MIT](LICENSE) · **ОС:** Windows · **Ветка:** `beside-continual-learning` · **Релиз:** [v1.2.0-beside-continual-learning](https://github.com/dapetun/cursor-hindsight-ondemand/releases/tag/v1.2.0-beside-continual-learning). [v1.1.0](https://github.com/dapetun/cursor-hindsight-ondemand/releases/tag/v1.1.0) на `main` по-прежнему включает автоматический recall/retain.

**Парный проект (public MIT):** [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator) — [README](https://github.com/dapetun/cursor-model-orchestrator#readme) · [v0.1.0](https://github.com/dapetun/cursor-model-orchestrator/releases/tag/v0.1.0) · [stack.md](https://github.com/dapetun/cursor-model-orchestrator/blob/main/docs/integrations/stack.md)

**cursor-hindsight-ondemand** поднимает локальный демон [Hindsight](https://github.com/vectorize-io/hindsight) только когда нужна агентская работа в Cursor, не при входе в Windows. На этой ветке `sessionStart` только проверяет `/health` и стартует демон. Явный MCP остаётся на `127.0.0.1`.

> **Коротко:** Hindsight на Windows без демона 24/7 и без второго автоматического цикла памяти рядом с плагином Continual Learning. Обёртки проверяют `/health`, поднимают локальный демон для MCP и не уходят в облако.

## Что это такое?

cursor-hindsight-ondemand - обёртки Windows, которые стартуют локальный Hindsight по требованию. Путь: ensure, затем явный MCP на `http://127.0.0.1:9077`. Между сессиями демон не обязан держать RAM. Дашборды Memory & Graphs остаются и стартуют только по запросу.

Это не замена Hindsight, не Continual Learning и не роутер моделей. Роутинг: [cursor-model-orchestrator](https://github.com/dapetun/cursor-model-orchestrator), профиль **stack**. Retain оркестратора, если он есть, идёт через MCP `hindsight`, не через хук `stop`.

## Рядом с Continual Learning

Плагин Continual Learning уже ведёт фоновую память: хук `stop` читает транскрипт и дописывает в `AGENTS.md` секции `## Learned User Preferences` и `## Learned Workspace Facts`. Cursor подхватывает этот файл в следующих чатах.

Эта ветка убирает тот же цикл у Hindsight:

| Continual Learning | Снято здесь |
|--------------------|-------------|
| `stop` читает транскрипт | нет хука `stop` и нет `retain.py` |
| предпочтения и факты workspace попадают в `AGENTS.md` | `autoRetain: false` |
| следующие чаты видят эти пункты через `AGENTS.md` | нет `session_start.py` и нет `.cursor/rules/hindsight-session.mdc` |

Ветка `main` (релиз v1.1.0) этот автоматический цикл сохраняет.

Здесь остаётся то, чего у плагина нет: демон по требованию, явный MCP и хаб дашбордов.

## Кому это нужно

- Нужен явный локальный MCP Hindsight, а предпочтения и факты workspace уже пишет Continual Learning в `AGENTS.md`
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
| Нет Continual Learning, нужен автоматический recall/retain | ветка `main`, релиз v1.1.0 |

## Как работает

1. Хук `sessionStart` проверяет `/health` и при необходимости стартует демон. Recall в промпт не пишет.
2. MCP: тот же ensure, затем `mcp-remote` на локальный endpoint. `recall` / `retain` / `reflect` вызываются явно.
3. В `cursor.json`: `"hindsightApiUrl": "http://127.0.0.1:9077"`, `"autoRecall": false`, `"autoRetain": false`.

Холодный старт обычно **40–120 с**; таймаут хука — **180**.

## Конфиденциальность и данные

**Не юридическая консультация.** Подробно: [docs/PRIVACY.md](docs/PRIVACY.md) · чеклист: [docs/COMPLIANCE.md](docs/COMPLIANCE.md) · уязвимости: [SECURITY.md](SECURITY.md).

- HTTP/MCP API памяти — только `127.0.0.1:9077`; нелокальный `BaseUrl` без `-AllowNonLocal` отклоняется.
- Локальный API **не** означает, что LLM (Hindsight embed / Cursor) никогда не увидит текст сессии.
- В `cursor.json` этой ветки `autoRecall` и `autoRetain` выключены. Автоматический retain транскрипта есть на `main`.

## Установка

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
git checkout beside-continual-learning
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

Нет. Только старт демона по требованию. Явные инструменты памяти остаются на MCP Hindsight.

### Это замена Continual Learning?

Нет. Плагин сам дописывает `AGENTS.md`. Эта ветка не пишет `Learned User Preferences` / `Learned Workspace Facts` и не кладёт параллельный rules-файл на старте сессии.

Если включён официальный плагин Hindsight для Cursor, отключите его хуки `sessionStart` (`session_start.py`) и `stop` (`retain.py`). Иначе он вернёт снятый цикл.

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
