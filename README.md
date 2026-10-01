# Cursor Hindsight on-demand

Local long-term memory for Cursor — started when you actually need it, not when Windows boots.

Hindsight is great as a local daemon, but leaving it in Startup wastes RAM and CPU all day. These small wrappers turn it on from Cursor itself: when an agent session starts, or when MCP tools are loaded. Between chats, nothing has to sit in the background.

This repo is the glue (scripts + example configs). You still install [Hindsight](https://github.com/vectorize-io/hindsight) and [Cursor](https://cursor.com) yourself.

## How it works

1. **Agent session** — a `sessionStart` hook checks `http://127.0.0.1:9077/health`. If the daemon is down, it starts it, waits until it is ready (up to about two and a half minutes), then runs the normal Hindsight recall.
2. **MCP tools** — the same check runs before opening a stdio proxy to the local Hindsight MCP endpoint.
3. **Local only** — keep `hindsightApiUrl` pointed at `127.0.0.1:9077` so a cold start never quietly falls through to the hosted cloud API.

The first launch after idle can take roughly **40–120 seconds** while models and the DB warm up. Set the Cursor `sessionStart` timeout to **180** so that first chat can wait.

## Requirements

- Windows with PowerShell  
- Cursor  
- Hindsight local / embed + the official Cursor integration (so `session_start.py` / `retain.py` are on disk)  
- Python 3 (hooks)  
- Node.js with `npx` (MCP launcher)

If `session_start.py` fails with `ModuleNotFoundError: lib.rules_file`, your Hindsight install is missing `rules_file.py` — grab that file from the upstream Cursor integration and place it next to the other plugin `lib` modules.

## Install

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
.\install.ps1
```

Copy the wrappers into `%USERPROFILE%\.hindsight`. To also drop example Cursor configs (existing files are left alone; examples are written beside them):

```powershell
.\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson
```

Then:

1. Make sure `~/.hindsight/cursor.json` uses `"hindsightApiUrl": "http://127.0.0.1:9077"`.
2. Remove any Windows Startup shortcut that used to start the daemon at login.
3. Reload Cursor.

Manual install works too: copy `scripts/*` into `~/.hindsight` and merge the JSON under `examples/` into `~/.cursor` / `~/.hindsight` as you prefer.

## Repository layout

```text
scripts/          wrappers installed under ~/.hindsight
examples/         sample hooks.json, mcp.json, cursor.json
install.ps1       copies scripts (optional config writers)
LICENSE           MIT
NOTICE            third-party attributions
```

## License

MIT — see [LICENSE](LICENSE). Third-party software you install separately is listed in [NOTICE](NOTICE).

---

# Cursor Hindsight по требованию

Локальная долгосрочная память для Cursor — включается, когда она реально нужна, а не при загрузке Windows.

Hindsight удобен как локальный демон, но держать его в автозагрузке — лишняя нагрузка на весь день. Эти небольшие обёртки поднимают его из самого Cursor: в начале агентской сессии или при подключении MCP. Пока чата нет, фоновый процесс не обязателен.

Здесь только «клей» (скрипты и примеры конфигов). [Hindsight](https://github.com/vectorize-io/hindsight) и [Cursor](https://cursor.com) ставятся отдельно.

## Как это устроено

1. **Агентская сессия** — хук `sessionStart` проверяет `http://127.0.0.1:9077/health`. Если демон молчит, запускает его, ждёт готовности (до ~2,5 минут) и делает обычный recall Hindsight.
2. **Инструменты MCP** — та же проверка перед stdio-прокси к локальному MCP Hindsight.
3. **Только localhost** — в `hindsightApiUrl` оставляйте `127.0.0.1:9077`, чтобы при холодном старте не уехать в облачный API.

Первый подъём после простоя обычно занимает **40–120 секунд**. Таймаут `sessionStart` в Cursor лучше поставить на **180**.

## Что нужно

- Windows и PowerShell  
- Cursor  
- Локальный Hindsight / embed и официальная интеграция для Cursor  
- Python 3 для хуков  
- Node.js с `npx` для MCP launcher  

Если `session_start.py` падает с `ModuleNotFoundError: lib.rules_file`, в установке не хватает `rules_file.py` — возьмите его из upstream Cursor-интеграции Hindsight.

## Установка

```powershell
git clone https://github.com/dapetun/cursor-hindsight-ondemand.git
cd cursor-hindsight-ondemand
.\install.ps1
```

Скрипты попадут в `%USERPROFILE%\.hindsight`. Примеры конфигов Cursor (существующие файлы не перезаписываются):

```powershell
.\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson
```

Дальше: локальный URL в `cursor.json`, убрать старый ярлык из автозагрузки Windows, перезагрузить Cursor.

## Структура

```text
scripts/          обёртки для ~/.hindsight
examples/         образцы hooks.json, mcp.json, cursor.json
install.ps1       копирование скриптов
LICENSE           MIT
NOTICE            сторонние компоненты
```

## Лицензия

MIT — [LICENSE](LICENSE). Стороннее ПО, которое ставится отдельно, перечислено в [NOTICE](NOTICE).
