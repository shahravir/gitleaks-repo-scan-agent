#!/usr/bin/env bash
# Scan many Git repositories with gitleaks; write one report per repo and a summary.
set -euo pipefail

origin_host() {
  # Prints lowercase hostname from `git remote get-url origin` (empty if missing / unparsable).
  local repo="$1" url
  url="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
  [[ -z "$url" ]] && { echo ""; return; }
  printf '%s' "$url" | python3 -c "
import sys
from urllib.parse import urlparse

def host_of_git_remote(url: str) -> str:
    url = url.strip()
    if not url:
        return ''
    if url.startswith('git@'):
        rest = url.split('@', 1)[1]
        return rest.split(':', 1)[0].lower()
    if '://' not in url and url.count(':') == 1:
        # scp-style host:path (no scheme)
        return url.split(':', 1)[0].lower()
    p = urlparse(url)
    return (p.hostname or '').lower()

print(host_of_git_remote(sys.stdin.read()))
"
}

usage() {
  sed -n '1,100p' <<'EOF'
Usage: scan-repos.sh [--root DIR] [--maxdepth N] [--out DIR] [--format FMT] [--verbose] [--exit-zero] [--require-origin-host HOST] [--] [REPO_DIR ...]

  --root DIR      Directory to search for Git repos (default: current directory).
  --maxdepth N    Passed to find(1) from --root (default: 3). Use 2 for root/owner/repo/.git layouts.
  --out DIR       Report output directory (default: ./gitleaks-reports).
  --format FMT    gitleaks --report-format (default: json). Try: sarif, json, csv, junit.
  --verbose       Pass --verbose to gitleaks.
  --exit-zero     Pass --exit-code 0 to gitleaks (do not fail individual scans on findings).
  --require-origin-host HOST
                  Skip repos unless git remote get-url origin resolves to this hostname (case-insensitive).
                  Repos without origin are skipped.

Positional REPO_DIR arguments: scan only these directories (must contain .git).

If no positional dirs are given, discover repos with:
  find <root> -maxdepth <maxdepth> -type d -name .git

Requires: gitleaks on PATH; python3 on PATH when using --require-origin-host.
EOF
}

ROOT="."
MAXDEPTH="3"
OUT="./gitleaks-reports"
FORMAT="json"
VERBOSE=()
EXIT_ZERO=()
REQUIRE_ORIGIN_HOST=""
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --root) ROOT="${2:?}"; shift 2 ;;
    --maxdepth) MAXDEPTH="${2:?}"; shift 2 ;;
    --out) OUT="${2:?}"; shift 2 ;;
    --format) FORMAT="${2:?}"; shift 2 ;;
    --verbose) VERBOSE=(--verbose); shift ;;
    --exit-zero) EXIT_ZERO=(--exit-code 0); shift ;;
    --require-origin-host) REQUIRE_ORIGIN_HOST="${2:?}"; shift 2 ;;
    --) shift; POSITIONAL+=("$@"); break ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      POSITIONAL+=("$1")
      shift
      ;;
  esac
done

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "gitleaks not found on PATH. Install: brew install gitleaks" >&2
  exit 127
fi

ROOT="$(cd "$ROOT" && pwd)"
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"

REPOS=()
if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
  REPOS=("${POSITIONAL[@]}")
else
  while IFS= read -r line; do
    [[ -n "$line" ]] && REPOS+=("$line")
  done < <(find "$ROOT" -maxdepth "$MAXDEPTH" -type d -name .git 2>/dev/null \
    | sed 's|/\.git$||' | sort -u)
fi

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "No Git repositories found under $ROOT (maxdepth=$MAXDEPTH)." >&2
  exit 3
fi

if [[ -n "$REQUIRE_ORIGIN_HOST" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found on PATH (required for --require-origin-host)." >&2
    exit 127
  fi
  req_lc="$(printf '%s' "$REQUIRE_ORIGIN_HOST" | tr '[:upper:]' '[:lower:]')"
  filtered=()
  for repo in "${REPOS[@]}"; do
    [[ ! -d "$repo/.git" ]] && continue
    host="$(origin_host "$repo")"
    if [[ -z "$host" ]]; then
      echo "Skip (no origin or unknown URL): $repo" >&2
      continue
    fi
    if [[ "$host" != "$req_lc" ]]; then
      echo "Skip (origin host=$host, require $req_lc): $repo" >&2
      continue
    fi
    filtered+=("$repo")
  done
  REPOS=("${filtered[@]}")
fi

if [[ ${#REPOS[@]} -eq 0 ]]; then
  echo "No repositories left after filters (e.g. --require-origin-host)." >&2
  exit 3
fi

SUMMARY="$OUT/summary.tsv"
printf 'repo\texit_code\treport_path\n' >"$SUMMARY"

failures=0
for repo in "${REPOS[@]}"; do
  if [[ ! -d "$repo/.git" ]]; then
    echo "Skip (not a git repo): $repo" >&2
    continue
  fi
  name="$(basename "$repo")"
  safe_name="${name//[^A-Za-z0-9._-]/_}"
  report="$OUT/${safe_name}.${FORMAT}"
  echo "==> gitleaks: $repo" >&2
  set +e
  gitleaks detect \
    --source "$repo" \
    --report-path "$report" \
    --report-format "$FORMAT" \
    --redact \
    "${VERBOSE[@]}" \
    "${EXIT_ZERO[@]}"
  code=$?
  set -e
  printf '%s\t%s\t%s\n' "$repo" "$code" "$report" >>"$SUMMARY"
  if [[ "$code" -ne 0 && ${#EXIT_ZERO[@]} -eq 0 ]]; then
    failures=$((failures + 1))
  fi
done

echo >&2
echo "Reports: $OUT" >&2
echo "Summary: $SUMMARY" >&2
echo "Repos with non-zero exit: $failures" >&2

if [[ "$failures" -gt 0 && ${#EXIT_ZERO[@]} -eq 0 ]]; then
  exit 1
fi
exit 0
