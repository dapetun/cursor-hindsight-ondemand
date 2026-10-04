# Compliance checklist (adopters & maintainers)

**Last updated:** 2026-10-03 · **Not legal advice.**

Use this when deploying the stack in an organization or before turning related work into a commercial service.

## A. Using this repo as published (local glue)

| Item | Status target | Notes |
|------|---------------|-------|
| Memory API on localhost only | Required | `hindsightApiUrl` / ensure `BaseUrl` |
| Non-local ensure blocked | Required | No `-AllowNonLocal` in prod images |
| LLM provider documented | Required | `start-daemon` env / `cursor.json` |
| Retain volume reviewed | Recommended | Prefer `examples/cursor.json` over full-retain |
| Wipe procedure known | Recommended | [PRIVACY.md](PRIVACY.md) |
| Cursor + Hindsight ToS accepted | Required | Upstream products |
| Employee/contractor notice (org) | Org policy | Chats may be retained locally |

## B. Before a Russian commercial website / SaaS

Owner actions (code in *this* repo cannot complete them):

- [ ] Реквизиты оператора (наименование, ИНН, ОГРН, адрес, телефон) — реальные, не плейсхолдеры
- [ ] Политика обработки ПДн + ссылки у форм
- [ ] Cookie / tracker consent gate if analytics are added
- [ ] Уведомление оператора в Роскомнадзор (152-ФЗ ст. 22) when applicable
- [ ] Локализация БД ПДн граждан РФ (ст. 18 ч. 5) + трансграница (ст. 12)
- [ ] ДОУ / поручение при привлечении обработчиков
- [ ] Оферта / возврат if selling to consumers (ЗОЗПП)

Draft section list: skill templates under a lawyer’s review — do not publish invented реквизиты.

## C. GDPR / international (if EEA/UK personal data)

- [ ] Record of processing / lawful bases
- [ ] DPA with processors (LLM, hosting, Cursor enterprise terms as applicable)
- [ ] Transfer mechanism if data leaves EEA
- [ ] DSAR path for memory bank contents
- [ ] Retention schedule + deletion runbook

## D. EU AI Act (full stack)

- [ ] Map roles: provider vs deployer for Cursor / models / any custom AI
- [ ] Article 50 transparency sits with the interacting AI system, not these wrappers alone
- [ ] Separate legal review if offering AI systems in the EU

## E. OSS maintainer hygiene (this repository)

| Artifact | Location |
|----------|----------|
| License | [LICENSE](../LICENSE) (MIT) |
| Third-party | [NOTICE](../NOTICE) |
| Privacy note | [PRIVACY.md](PRIVACY.md) |
| Security | [SECURITY.md](../SECURITY.md) |
| Contributions / DCO | [CONTRIBUTING.md](../CONTRIBUTING.md), [DCO](../DCO) |

## Related

- [INTEGRATIONS.md](INTEGRATIONS.md) — product boundary vs orchestrator / GitNexus
- [PRIVACY.md](PRIVACY.md) — data flows in plain language
