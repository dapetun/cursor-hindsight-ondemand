# Contributing

Thanks for helping improve **cursor-hindsight-ondemand**.

## License inbound = outbound

This project is licensed under the [MIT License](LICENSE). By contributing, you agree that your contribution is provided under the same MIT terms (inbound = outbound). See also [NOTICE](NOTICE) for third-party software that is **not** redistributed from this tree.

## Developer Certificate of Origin (DCO)

We use the [Developer Certificate of Origin](https://developercertificate.org/) instead of a CLA.

Every commit must include a sign-off trailer:

```text
Signed-off-by: Your Name <your.email@example.com>
```

Create signed-off commits with:

```bash
git commit -s -m "Describe the change."
```

Or amend the last commit:

```bash
git commit --amend -s --no-edit
```

The sign-off certifies the text in [DCO](DCO) (identical to DCO 1.1).

### Pull requests

- Open PRs against `main`.
- Keep scope tight: wrappers, examples, docs for on-demand local Hindsight on Windows.
- Do not vend Cursor, Hindsight binaries, or GitNexus.
- Update README / `llms.txt` / `docs/` when behavior or defaults change.
- Use the PR template checklist (DCO + privacy note if you touch data paths).

## Local check

```powershell
# From repo root after editing scripts
.\install.ps1
# Optional: refresh example configs (won't overwrite existing user files)
.\install.ps1 -WriteHooks -WriteMcp -WriteCursorJson
```

Confirm `ensure-daemon.ps1` still refuses a non-local URL without `-AllowNonLocal`.

## Code of collaboration

- No secrets in commits (API keys, tokens, personal paths with private data).
- Prefer localhost-safe defaults; document any override that weakens that posture.
- Security reports: [SECURITY.md](SECURITY.md), not public issues.
