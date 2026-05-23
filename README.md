# Gitleaks Repository Scan Agent

AI agent skill for **shift-left secret scanning** — runs Gitleaks on one repo, a list of paths, or every Git clone under a root directory, then interprets JSON/SARIF reports and suggests remediation.

Built for agentic engineering workflows (Cursor, Copilot CLI, and similar tools).

## What it does

- Scans repositories for leaked secrets, API keys, tokens, and credentials
- Supports single-repo, multi-repo, and bulk hygiene across clone directories
- Bundled shell scripts for consistent flags, per-repo reports, and summaries
- Optional filtering by `origin` remote host

## Contents

| Path | Purpose |
|------|---------|
| `SKILL.md` | Agent skill definition and workflow |
| `prompts.md` | Prompt templates for scan interpretation |
| `reference.md` | Gitleaks flags and report formats |
| `scripts/` | `scan-repos.sh`, clone pruning utilities |

## Prerequisites

```bash
brew install gitleaks   # macOS
gitleaks version
```

## Quick start

**Single repository:**

```bash
gitleaks detect --source /path/to/repo --report-format json --report-path gitleaks-report.json
```

**Multiple repos under a root:**

```bash
zsh scripts/scan-repos.sh --root /path/to/parent --maxdepth 2
```

See `SKILL.md` for the full agent workflow, SARIF interpretation, and remediation guidance.

## Related writing

Shift-left security and AI-powered code scans: [Medium — IBM Project Bob](https://medium.com/@shah.ravir)

---

**Ravi Shah** — Agentic engineering · Financial Services  
Hub: https://shahravir.github.io · [LinkedIn](https://www.linkedin.com/in/ravishah01/) · [Medium](https://medium.com/@shah.ravir) · [DEV](https://dev.to/shahravir)
