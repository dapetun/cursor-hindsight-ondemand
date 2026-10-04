# Privacy & data handling

**Last updated:** 2026-10-03

> **Not legal advice.** This note describes what *this repository* does and does not do with data. It is an engineering disclosure for installers and org adopters. A licensed lawyer must review any text you publish as a formal privacy policy, оферта, or operator notice (152-ФЗ / GDPR).

## What this project is

**cursor-hindsight-ondemand** ships Windows wrappers that start a **local** Hindsight daemon (`hindsight-embed`) for Cursor and proxy MCP to `http://127.0.0.1:9077`. It does **not** operate a hosted memory service, website, signup form, analytics pixel, or payment flow.

The copyright holder of this repository is **not**, by distributing these scripts alone, collecting personal data from end users over the internet.

## What can end up on disk

When you install and enable hooks/MCP, **your machine** may store agent-session content via upstream Hindsight retain/recall (plugin scripts under `~/.hindsight/plugin-host/…`). Typical categories:

| Category | Examples | Who controls it |
|----------|----------|-----------------|
| Chat / agent turns | Prompts, tool results, code snippets pasted into Cursor | You (local Hindsight bank) |
| Config | `~/.hindsight/cursor.json`, LLM provider/model names | You |
| Process metadata | Health checks against `127.0.0.1:9077` | Local only |

This repository’s wrappers do not upload that bank to a cloud API URL. They are written to refuse non-local `BaseUrl` values unless you pass an explicit override (see [SECURITY.md](../SECURITY.md)).

## Local API ≠ “nothing leaves the machine”

Keep these layers separate:

1. **Memory API** — intended: `hindsightApiUrl` / ensure `BaseUrl` = `http://127.0.0.1:9077` only.
2. **Hindsight embed LLM** — `start-daemon.ps1` sets `HINDSIGHT_API_LLM_PROVIDER` / `HINDSIGHT_API_LLM_MODEL` (example defaults: `openai-codex` + a model id). Depending on upstream Hindsight and your credentials, **embedding or memory processing may call an external LLM**.
3. **Cursor IDE** — proprietary product; its own telemetry, model providers, and privacy terms apply independently of this repo.

Reading “local memory” in the README means the **Hindsight HTTP API** stays on localhost, not that every token of every agent turn is guaranteed never to leave the PC.

## Safer retain defaults

Example `examples/cursor.json` uses **leaner** retain pacing (`retainEveryNTurns: 5`) than an every-turn full dump. For maximum capture see `examples/cursor.full-retain.json`. Org adopters should prefer lean retain and define retention/wipe policy internally.

## How to wipe local memory (operator self-help)

Exact DB paths depend on your Hindsight install. Practical wipe checklist:

1. Quit Cursor (so hooks/MCP stop calling the daemon).
2. Stop the local daemon (`hindsight-embed` for profile `cursor`), if running.
3. Remove or reset the Hindsight data directory for the `cursor` bank (see upstream Hindsight docs).
4. Optionally delete `~/.hindsight/cursor.json` and reinstall wrappers with `.\install.ps1`.
5. Rotate any API keys that may have been pasted into chats and retained.

If you cannot find the bank files, treat upstream Hindsight documentation as authoritative — this repo only starts the daemon.

## Roles (GDPR / 152-ФЗ signpost)

| Situation | Typical role |
|-----------|----------------|
| You run wrappers + local Hindsight on your PC for personal use | You decide what is stored; this repo’s authors are not your processor for that bank |
| Employer mandates Cursor + memory on company laptops | Org is usually controller; review Cursor + Hindsight + LLM DPAs separately |
| You build a **hosted** multi-tenant memory SaaS using these ideas | You become operator/controller — need notices, ДОУ/DPA, RKN/GDPR processes (**out of scope** of this glue repo) |

## Russian-facing adopters (152-ФЗ)

This repository is not a Russian commercial website. If you later ship a `.ru` landing page, collect emails, or process ПДн of Russian citizens as an **operator**:

- Publish a privacy policy and obtain required consents before collection.
- File operator notification with Роскомнадзор when required.
- Respect localization (152-ФЗ ст. 18 ч. 5) and cross-border rules (ст. 12) for any non-RF databases or vendors.
- Do **not** treat this MIT glue as a substitute for those duties.

Placeholders for a future formal policy (fill only with real реквизиты; never invent ИНН/ОГРН):

- Оператор: `{{ПОЛНОЕ_НАИМЕНОВАНИЕ}}`, ИНН `{{ИНН}}`, ОГРН `{{ОГРН}}`, адрес `{{ЮР_АДРЕС}}`, email `{{EMAIL}}`.

## EU / GDPR signpost

If you process personal data of people in the EEA/UK as a controller:

- Document lawful basis, retention, and subprocessors (Cursor, LLM vendor, any hosted Hindsight).
- Provide a way to access/erase data in the memory bank.
- Prefer localhost memory API; document any international transfers from LLM calls.

## AI Act signpost

These wrappers are lifecycle glue, not an AI model. Transparency / provider duties for AI interactions generally sit with Cursor and model providers. Org deployers should map roles for the full stack separately.

## Contact for this repository

Security issues: see [SECURITY.md](../SECURITY.md).  
General project: GitHub issues on [dapetun/cursor-hindsight-ondemand](https://github.com/dapetun/cursor-hindsight-ondemand).

---

# Конфиденциальность и данные (RU)

**Обновлено:** 2026-10-03

> **Не юридическая консультация.** Ниже — инженерное описание поведения репозитория.

Этот проект **не** собирает ПДн через сайт и **не** хостит облачную память. Обёртки держат HTTP API Hindsight на `127.0.0.1:9077` и отказывают нелокальному `BaseUrl` без явного override.

**Важно:** локальный API памяти ≠ гарантия, что LLM (Hindsight embed / Cursor) никогда не получит текст сессии. Проверяйте провайдера модели и условия Cursor.

Хранение сессий — у вас локально через upstream retain. Пример `cursor.json` использует более редкий retain; агрессивный вариант — `cursor.full-retain.json`. Как стереть банк — см. английскую секцию wipe выше и документацию Hindsight.

При коммерческом сборе ПДн граждан РФ (лендинг, SaaS) нужны отдельные политика, уведомление РКН, локализация и договоры — этот MIT-glue их не закрывает.
