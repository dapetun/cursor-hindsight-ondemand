# Security policy

**Last updated:** 2026-10-03

## Supported versions

| Version | Supported |
|---------|-----------|
| `main` / latest release tag | Yes |
| Older tags | Best effort only |

## What this software trusts

- Local loopback only for the Hindsight HTTP/MCP API (`127.0.0.1` / `localhost` / `::1`).
- Upstream `hindsight-embed`, official Hindsight Cursor plugin scripts, Node/`npx`, and PowerShell on the installer machine.
- Cursor IDE and any LLM credentials already present in the user environment.

## Hardening in this repo

1. **Local-only ensure** — `scripts/ensure-daemon.ps1` rejects non-local `-BaseUrl` unless `-AllowNonLocal` is passed (loud warning). Prefer never using that switch.
2. **Hardcoded MCP URL** — `scripts/mcp-launch.mjs` proxies only to `http://127.0.0.1:9077/mcp/cursor/`.
3. **No cloud fallback in wrappers** — session-start and MCP launch do not rewrite `hindsightApiUrl` to a hosted endpoint.
4. **Leaner example retain** — see `examples/cursor.json` vs `examples/cursor.full-retain.json`.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for exploitable flaws.

1. Use GitHub **Private vulnerability reporting** on [dapetun/cursor-hindsight-ondemand](https://github.com/dapetun/cursor-hindsight-ondemand) if available, **or**
2. Open a security-focused contact via the maintainer’s GitHub profile for `dapetun`.

Include: affected commit/tag, OS, reproduction steps, and impact (e.g. non-local URL accepted, command injection, unexpected network egress from wrappers).

We aim to acknowledge within 14 days. Fixes are coordinated before public disclosure when practical.

## Out of scope (report upstream)

| Component | Where |
|-----------|--------|
| `hindsight-embed` / Hindsight Cloud | [vectorize-io/hindsight](https://github.com/vectorize-io/hindsight) |
| Cursor IDE / agent runtime | [cursor.com](https://cursor.com) / Anysphere |
| `mcp-remote` npm package | npm / package maintainers |

## Operator checklist

- [ ] `~/.hindsight/cursor.json` → `"hindsightApiUrl": "http://127.0.0.1:9077"`
- [ ] No Startup shortcut forcing a misconfigured daemon
- [ ] LLM provider/model in `start-daemon` / env reviewed for data egress
- [ ] Org devices: disk encryption, least-privilege accounts, wipe procedure ([docs/PRIVACY.md](docs/PRIVACY.md))
- [ ] Secrets pasted into chats treated as compromised if retain was enabled

## Privacy

See [docs/PRIVACY.md](docs/PRIVACY.md).
