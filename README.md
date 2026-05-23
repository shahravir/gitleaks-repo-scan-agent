# Gitleaks Repository Scan Agent

> **Shift-left security for the agentic engineering era** — an AI agent skill that runs [Gitleaks](https://github.com/gitleaks/gitleaks) secret scans inside developer workflows (Cursor, Copilot CLI, CI), interprets findings, and guides remediation before secrets reach production.

Companion open-source artifact to [*IBM Project Bob Shifts Security Left with AI-Powered Code Scans*](https://medium.com/@shah.ravir) — exploring what happens when security scanning moves from a pipeline gate to an **autonomous agent in the PR loop**.

---

## The problem this solves

Every CISO team wants **shift-left security**. In practice, that has meant:

- Developers run Gitleaks manually (sometimes)
- Findings sit in CI logs nobody reads
- Agents write code faster than security review scales

This skill closes that gap: give an AI agent a **repeatable, redacted, auditable** scan workflow it can invoke on demand — one repo, a list of paths, or every clone under a workspace root.

```
Developer / Agent                This skill                    Outcome
─────────────────               ───────────                   ───────
"Scan my clones for secrets" →  Gitleaks + scripts      →     Grouped findings
"Check this PR for leaks"    →  JSON/SARIF + redact     →     Rotate / revoke guidance
"Hygiene across 40 repos"    →  Bulk scan + summary     →     Prioritised remediation
```

---

## Features

| Capability | Detail |
|------------|--------|
| **Single-repo scan** | Full git history or working-tree-only |
| **Bulk scan** | All Git repos under a root directory with consistent flags |
| **Origin filtering** | Limit scans to clones from a specific host (`--require-origin-host`) |
| **Clone pruning** | Remove stale working trees by origin (dry-run by default) |
| **Safe reporting** | JSON/SARIF output with `--redact` for chat and CI logs |
| **Agent-native** | `SKILL.md` workflow for Cursor / Copilot-style tools |

---

## Repository layout

| Path | Purpose |
|------|---------|
| [`SKILL.md`](SKILL.md) | Agent skill definition — when to invoke, step-by-step workflow |
| [`prompts.md`](prompts.md) | Copy-paste prompts for scan interpretation |
| [`reference.md`](reference.md) | Gitleaks flags, report formats, baselines |
| [`scripts/scan-repos.sh`](scripts/scan-repos.sh) | Multi-repo scan with per-repo reports + summary |
| [`scripts/prune-clones-by-origin-host.sh`](scripts/prune-clones-by-origin-host.sh) | Workspace hygiene utility |

---

## Quick start

### 1. Install Gitleaks

```bash
brew install gitleaks          # macOS
# or: go install github.com/zricethezav/gitleaks/v8@latest
gitleaks version
```

### 2. Scan one repository

```bash
gitleaks detect --source /path/to/repo --verbose
```

Working tree only (no history):

```bash
gitleaks detect --source /path/to/repo --no-git --verbose
```

Redacted JSON report (safe to share with an agent):

```bash
gitleaks detect --source /path/to/repo \
  --report-path gitleaks.json --report-format json --redact
```

### 3. Scan all repos under a directory

```bash
zsh scripts/scan-repos.sh --root /path/to/clones --maxdepth 2
```

Filter by Git remote host:

```bash
zsh scripts/scan-repos.sh --root ~/projects --maxdepth 2 \
  --require-origin-host github.com
```

---

## Agent workflow (summary)

1. **Clarify scope** — single repo, explicit paths, or all clones under a root.
2. **Run scan** — prefer bundled scripts for bulk; use `--redact` when reports leave the machine.
3. **Interpret findings** — group by rule ID and file; distinguish true secrets from false positives.
4. **Remediate** — rotate/revoke credentials; history purge (`git filter-repo` / BFG) **only with explicit consent**.
5. **Baseline carefully** — `.gitleaksignore` or `--baseline-path` for documented false positives; never baseline real secrets.
6. **Align with CI** — same `gitleaks detect` command locally and in the pipeline.

Full workflow: [`SKILL.md`](SKILL.md)

---

## Use with Cursor

Copy this repo's skill into your project:

```text
.cursor/skills/gitleaks-repo-scan/
```

Or clone and reference `SKILL.md` directly. The agent triggers on prompts like:

- *"Scan this repo for leaked secrets"*
- *"Run gitleaks on all my clones under ~/projects"*
- *"Check this PR for credentials before I merge"*

---

## How this connects to IBM Project Bob

[IBM Project Bob](https://medium.com/@shah.ravir) explores AI-powered code scanning embedded in the developer loop — not as a separate security gate, but as **continuous, contextual inspection** while code is written.

This repository is the **open, agent-portable slice** of that idea:

- **Gitleaks** as the deterministic scanner (no hallucinated findings)
- **An agent skill** as the orchestration layer (scope, interpretation, remediation)
- **Redaction by default** so security work can happen inside AI chat safely

Same pattern applies beyond secrets: SAST, dependency audit, policy checks — scanner provides ground truth; agent provides reach and narrative.

→ Read the full article: [**IBM Project Bob Shifts Security Left with AI-Powered Code Scans**](https://medium.com/@shah.ravir)

---

## Defaults this skill assumes

- Scan **git history** unless filesystem-only or staged-only is requested.
- Use **`--redact`** whenever reports may leave the user's machine.
- For "all clones under this folder", use `--root` + `--maxdepth 2` when layout is `root/<repo>/.git`.

---

## Contributing

Issues and PRs welcome. Keep changes aligned with the agent-skill format in `SKILL.md`.

---

**Ravi Shah** — Agentic engineering · Financial Services  
Executive Architect, IBM Consulting UKI · *Views my own.*

Hub: https://shahravir.github.io · [LinkedIn](https://www.linkedin.com/in/ravishah01/) · [Medium](https://medium.com/@shah.ravir) · [DEV](https://dev.to/shahravir)
