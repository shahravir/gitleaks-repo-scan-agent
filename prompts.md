# Prompts: Gitleaks scans (copy into chat)

Use these verbatim or tweak paths. Replace `<ROOT>` with a directory that contains one or more Git checkouts.

## Single repository

```
Run gitleaks on this repo only: <ROOT>/my-service
Use --verbose and --redact. If anything is found, summarize by rule ID and file, and tell me what to rotate first.
```

## All Git repositories under a folder

```
Scan every Git repository under <ROOT> with gitleaks using the project script
.cursor/skills/gitleaks-repo-scan/scripts/scan-repos.sh --root <ROOT> --maxdepth 2
Then open the combined summary: which repos failed, how many findings each, top rules.
```

## Only clones whose origin matches a host

```
Under <ROOT> (maxdepth 2), run
.cursor/skills/gitleaks-repo-scan/scripts/scan-repos.sh --root <ROOT> --maxdepth 2 --require-origin-host git.example.com
Then summarize failures, counts per repo, and top rule IDs from the JSON reports.
```

## Remove clones by origin host (cleanup)

```
List what would be deleted under <ROOT> (maxdepth 2) when origin matches suffix internal.example.com:
.cursor/skills/gitleaks-repo-scan/scripts/prune-clones-by-origin-host.sh --root <ROOT> --maxdepth 2 --delete-when-origin-host-suffix internal.example.com
If the list looks right, repeat with --execute. Then re-run scan-repos.sh as needed.
```

## Pre-push / pre-commit style (staged changes)

```
In repo <ROOT>/my-service, run gitleaks in protect mode on staged files (--staged).
If leaks exist, show the hunks/rules and how to fix without committing secrets.
```

## Working tree only (fast sanity check)

```
Gitleaks filesystem scan only (--no-git) for <ROOT>/my-app. Explain limitations vs full history scan.
```

## CI parity

```
Give me a single gitleaks detect command I can paste into GitHub Actions for repo <ROOT>/api
that fails the job on leaks, writes SARIF as an artifact, and uses --redact.
```

## After a leak is found

```
We found gitleaks rule generic-api-key in file src/config.ts. Do not print the secret.
List remediation: rotate key, remove from history options, and a safe .gitleaksignore ONLY if this is a false positive — justify each ignore entry.
```
