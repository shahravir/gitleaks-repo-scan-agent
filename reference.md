# Gitleaks reference (compact)

## Common commands

| Goal | Command |
|------|---------|
| Many repos + summary | `scripts/scan-repos.sh --root /path --maxdepth 2` |
| Same, origin host filter | `scripts/scan-repos.sh --root /path --maxdepth 2 --require-origin-host git.example.com` |
| Delete clones by origin host | `scripts/prune-clones-by-origin-host.sh --help` (dry run unless `--execute`) |
| Default repo scan | `gitleaks detect --source . --verbose` |
| Verbose + exit 0 (audit mode) | `gitleaks detect --source . --verbose --exit-code 0` |
| JSON report | `gitleaks detect --source . --report-path report.json --report-format json --redact` |
| SARIF (tools / GitHub) | `gitleaks detect --source . --report-path report.sarif --report-format sarif --redact` |
| No git (files only) | `gitleaks detect --source . --no-git --verbose` |
| Staged only | `gitleaks protect --staged --verbose` (run inside repo) |

## Baseline and ignores

- **Baseline** (suppress known findings file): `--baseline-path gitleaks-baseline.json` — regenerate only after review; never used to hide unfixed leaks.
- **Repo ignore**: `.gitleaksignore` at repo root (path globs). Prefer fixing or rotating secrets over ignoring.

## Exit codes

- `0`: no leaks (or `--exit-code 0`).
- `1`: leaks detected (typical CI failure).

## Performance

- Large monorepos: consider `--log-opts` to limit commits if documented for that repo; default full-history scan is safest for secret detection.

## Links

- [Gitleaks documentation](https://github.com/gitleaks/gitleaks)
- [Default rules](https://github.com/gitleaks/gitleaks/blob/master/config/gitleaks.toml)
