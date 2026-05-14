---
name: gitleaks-repo-scan
description: >-
  Runs Gitleaks secret scanning on one Git repository, a list of paths, or every
  Git repo under a root directory; interprets JSON/SARIF reports and suggests
  remediation. Use when the user asks to scan for secrets, credentials, API
  keys, tokens, gitleaks, leaked passwords, pre-commit security checks, or bulk
  repo hygiene across clones.
---

# Gitleaks repository scan

## Prerequisites

1. **Install Gitleaks** (pick one):
   - macOS: `brew install gitleaks`
   - Go: `go install github.com/zricethezav/gitleaks/v8@latest`
   - Releases: [gitleaks releases](https://github.com/gitleaks/gitleaks/releases)

2. Confirm: `gitleaks version`

## Agent workflow

1. **Clarify scope**: single repo path, explicit list of directories, or “all Git repos under `<root>`”.
2. **Prefer the bundled script** for multiple repos (consistent flags, per-repo reports, summary):

   ```bash
   zsh .cursor/skills/gitleaks-repo-scan/scripts/scan-repos.sh --root /path/to/parent --maxdepth 2
   ```

   Optional: limit scans to clones whose **`origin`** matches a host (parsed from `git remote get-url origin`; needs `python3`):

   ```bash
   zsh .cursor/skills/gitleaks-repo-scan/scripts/scan-repos.sh --root /path/to/parent --maxdepth 2 --require-origin-host git.example.com
   ```

   Optional: remove working trees under a root by origin host (dry run by default; pass **`--execute`** to delete). See `scripts/prune-clones-by-origin-host.sh --help`.

3. **Single repo** (full git history is default):

   ```bash
   gitleaks detect --source /path/to/repo --verbose
   ```

4. **Working tree only** (no history):

   ```bash
   gitleaks detect --source /path/to/repo --no-git --verbose
   ```

5. **Redacted machine-readable output** (safe to paste in chat):

   ```bash
   gitleaks detect --source /path/to/repo --report-path gitleaks.json --report-format json --redact
   ```

6. **After findings**: group by rule ID and file; recommend rotate/revoke credentials, purge history (`git filter-repo` / BFG) only with explicit user consent; suggest `.gitleaksignore` or `--baseline-path` for documented false positives (never baseline away real secrets).

7. **CI alignment**: same `gitleaks detect` command the user runs in CI; prefer `--redact` in logs.

## Defaults this skill assumes

- Scan **git history** unless the user asks for filesystem-only or staged-only.
- Use **`--redact`** whenever reports may leave the user’s machine.
- For “all my clones under this folder”, set `--root` to that folder and `--maxdepth 2` when each repo is `root/<name>/.git`.

## Progressive disclosure

- Copy-paste prompts: [prompts.md](prompts.md)
- Flags, formats, baselines: [reference.md](reference.md)
