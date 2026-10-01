# Cursor Hindsight on-demand

Start the **local** Hindsight daemon only when Cursor agent work needs it — not at Windows logon.

This repository ships small wrapper scripts + example Cursor configs. It does **not** redistribute Hindsight, Cursor, or Node packages.

## License (MIT is OK)

**This wrapper is MIT-licensed** (see `LICENSE`).

Third-party licenses (dependencies you install yourself; see `NOTICE`):

| Component | License | Notes |
|-----------|---------|--------|
| Hindsight / hindsight-embed | MIT | Upstream: [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight) |
| mcp-remote | MIT | Pulled via `npx` at runtime |
| Cursor IDE | Proprietary | Not redistributed |

**GitNexus is intentionally not included.** It uses [PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/), which is not MIT and restricts commercial use. Keep code-graph tooling separate if you need a clean MIT wrapper.

You may publish this repo under MIT. Keep upstream copyright notices if you later vendor any Hindsight source files (this repo does not).

## What it does

1. **`sessionStart` hook** — `ensure-daemon.ps1` checks `http://127.0.0.1:9077/health`, starts the daemon if needed (waits up to ~150s), then runs the official Hindsight `session_start.py` recall.
2. **MCP launcher** — same ensure step, then `mcp-remote` proxies stdio ↔ local Hindsight MCP.
3. **No cloud fallback** — keep `hindsightApiUrl` set to `http://127.0.0.1:9077` so a down daemon does not silently switch to hosted Hindsight.

Cold start on a typical Windows machine was measured around **40–120 seconds**. Raise the Cursor `sessionStart` timeout to **180** so the first chat can wait.

## Prerequisites

- Windows + PowerShell
- [Cursor](https://cursor.com)
- Official Hindsight local/embed install + Cursor plugin/init (so `~/.hindsight/plugin-host/.../session_start.py` exists)
- Node.js (`npx`) for the MCP launcher
- Python 3 for Cursor hooks

Known upstream issue: some Hindsight `init` installs omit `scripts/lib/rules_file.py`, which breaks `session_start.py`. Copy that file from the upstream Hindsight Cursor integration if you hit `ModuleNotFoundError: lib.rules_file`.

## Install

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
.\install.ps1
# optional: write example configs (skips overwrite of existing files)
.\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson
```

Or copy `scripts/*` into `%USERPROFILE%\.hindsight\` and merge `examples/` into `%USERPROFILE%\.cursor\` / `%USERPROFILE%\.hindsight\cursor.json` by hand.

Then:

1. Confirm `~/.hindsight/cursor.json` uses `"hindsightApiUrl": "http://127.0.0.1:9077"`.
2. Remove any `Startup\hindsight-local-memory.cmd` (or similar) Windows autostart.
3. Reload Cursor.

## Layout

```
scripts/
  ensure-daemon.ps1              # health check + start
  start-daemon.ps1               # hindsight-embed daemon start
  mcp-launch.ps1                 # ensure + mcp-remote
  session-start-with-ensure.py   # Cursor sessionStart entry
examples/
  hooks.json
  mcp.json
  cursor.json
install.ps1
LICENSE
NOTICE
```

## Security notes

- Bind/use **localhost only** (`127.0.0.1`).
- Do not commit API keys or personal `cursor.json` with secrets.
- This project does not grant rights to Hindsight Cloud or any hosted service.

---

# Cursor Hindsight по требованию

Локальный демон Hindsight поднимается **только когда нужна агентская работа в Cursor**, а не при входе в Windows.

В репозитории — обёртки и примеры конфигов Cursor. **Hindsight, Cursor и npm-пакеты здесь не распространяются.**

## Лицензия (MIT можно)

**Обёртка под MIT** (файл `LICENSE`).

Чужие компоненты (ставите сами; см. `NOTICE`):

| Компонент | Лицензия | Заметки |
|-----------|----------|---------|
| Hindsight / hindsight-embed | MIT | Upstream: [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight) |
| mcp-remote | MIT | Подтягивается через `npx` |
| Cursor IDE | Проприетарный | Не входит в репозиторий |

**GitNexus намеренно не включён.** У него [PolyForm Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/) — это не MIT и ограничивает коммерческое использование. Граф кода лучше держать отдельно, чтобы обёртка оставалась чистым MIT.

Публиковать этот репозиторий под MIT можно. Если позже начнёте вендорить исходники Hindsight — сохраняйте их copyright notice (сейчас исходников Hindsight в репо нет).

## Что делает

1. **Хук `sessionStart`** — проверка `/health`, при необходимости старт демона (до ~150 с), затем официальный `session_start.py`.
2. **MCP launcher** — тот же ensure, затем `mcp-remote` между stdio и локальным MCP.
3. **Без ухода в облако** — в конфиге только `http://127.0.0.1:9077`.

Холодный старт обычно **40–120 с**; таймаут `sessionStart` лучше **180**.

## Установка

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
.\install.ps1
.\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson
```

Дальше: локальный URL в `cursor.json`, убрать автозагрузку Windows, перезагрузить Cursor.

Известный баг upstream: иногда нет `rules_file.py` — скопируйте файл из официальной Cursor-интеграции Hindsight.
