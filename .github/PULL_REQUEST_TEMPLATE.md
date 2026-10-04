## Summary

<!-- What changed and why -->

## Checklist

- [ ] Commits are DCO signed-off (`git commit -s`) — see [CONTRIBUTING.md](../CONTRIBUTING.md) / [DCO](../DCO)
- [ ] License remains MIT inbound=outbound; no CLA required
- [ ] If touching memory / network / URL defaults: localhost posture preserved or documented override
- [ ] Docs updated when behavior or examples change (`README`, `llms.txt`, `docs/PRIVACY.md` as needed)
- [ ] No secrets, API keys, or private paths committed

## Test plan

- [ ] `.\install.ps1` copies updated scripts
- [ ] `ensure-daemon.ps1` healthy on `http://127.0.0.1:9077`
- [ ] Non-local BaseUrl without `-AllowNonLocal` exits with error (if ensure changed)
