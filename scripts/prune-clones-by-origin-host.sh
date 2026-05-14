#!/usr/bin/env bash
# Remove Git working trees whose origin remote resolves to a given hostname (exact match, case-insensitive).
set -euo pipefail

usage() {
  sed -n '1,120p' <<'EOF'
Usage: prune-clones-by-origin-host.sh --root DIR --maxdepth N (--delete-when-origin-host HOST | --delete-when-origin-host-suffix SUF) [--execute]

  --root DIR                 Directory to search for Git repos (required).
  --maxdepth N               Passed to find(1) from --root (required).
  --delete-when-origin-host HOST
                             Remove when origin hostname equals HOST (case-insensitive).
  --delete-when-origin-host-suffix SUF
                             Remove when origin hostname equals SUF or ends with "." + SUF (leading dots
                             on SUF are ignored). Example suffix: internal.example.com
  --execute                  Actually delete. Without this flag, only prints what would be removed.

Provide exactly one of --delete-when-origin-host or --delete-when-origin-host-suffix.

Uses git remote get-url origin. Repos without origin are left unchanged.

Requires: python3 on PATH.

Safety: only deletes directories that are strict children of --root (resolved paths).
EOF
}

origin_host() {
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
        return url.split(':', 1)[0].lower()
    p = urlparse(url)
    return (p.hostname or '').lower()

print(host_of_git_remote(sys.stdin.read()))
"
}

ROOT=""
MAXDEPTH=""
TARGET_HOST=""
TARGET_SUFFIX=""
MODE=""
HOST_FLAG=0
SUFFIX_FLAG=0
EXECUTE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --root) ROOT="${2:?}"; shift 2 ;;
    --maxdepth) MAXDEPTH="${2:?}"; shift 2 ;;
    --delete-when-origin-host) TARGET_HOST="${2:?}"; MODE=host; HOST_FLAG=1; shift 2 ;;
    --delete-when-origin-host-suffix) TARGET_SUFFIX="${2:?}"; MODE=suffix; SUFFIX_FLAG=1; shift 2 ;;
    --execute) EXECUTE=1; shift ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$HOST_FLAG" -eq 1 && "$SUFFIX_FLAG" -eq 1 ]]; then
  echo "Use only one of --delete-when-origin-host or --delete-when-origin-host-suffix." >&2
  exit 2
fi

if [[ -z "$ROOT" || -z "$MAXDEPTH" || "$HOST_FLAG$SUFFIX_FLAG" -eq 0 ]]; then
  echo "Required: --root, --maxdepth, and one of --delete-when-origin-host / --delete-when-origin-host-suffix" >&2
  usage >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found on PATH." >&2
  exit 127
fi

ROOT="$(cd "$ROOT" && pwd)"
target_lc=""
suffix_base=""
if [[ "$MODE" == host ]]; then
  target_lc="$(printf '%s' "$TARGET_HOST" | tr '[:upper:]' '[:lower:]')"
else
  suffix_base="$(printf '%s' "$TARGET_SUFFIX" | sed 's/^[.]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')"
  if [[ -z "$suffix_base" ]]; then
    echo "Empty suffix after normalization." >&2
    exit 2
  fi
fi

host_matches() {
  local h="$1"
  if [[ "$MODE" == host ]]; then
    [[ "$h" == "$target_lc" ]] && return 0
    return 1
  fi
  [[ "$h" == "$suffix_base" ]] && return 0
  [[ "$h" == *".${suffix_base}" ]] && return 0
  return 1
}

repos=()
while IFS= read -r line; do
  [[ -n "$line" ]] && repos+=("$line")
done < <(find "$ROOT" -maxdepth "$MAXDEPTH" -type d -name .git 2>/dev/null \
  | sed 's|/\.git$||' | sort -u)

removed=0
for repo in "${repos[@]}"; do
  [[ ! -d "$repo/.git" ]] && continue
  real_repo="$(cd "$repo" && pwd)"
  case "$real_repo" in
    "$ROOT"|"$ROOT"/) continue ;;
    "$ROOT"/*) ;;
    *) echo "Skip (outside root): $real_repo" >&2; continue ;;
  esac
  host="$(origin_host "$real_repo")"
  [[ -z "$host" ]] && continue
  if ! host_matches "$host"; then
    continue
  fi
  if [[ "$EXECUTE" -eq 1 ]]; then
    echo "Removing: $real_repo" >&2
    rm -rf "$real_repo"
    removed=$((removed + 1))
  else
    echo "Would remove: $real_repo" >&2
    removed=$((removed + 1))
  fi
done

if [[ "$EXECUTE" -eq 0 ]]; then
  echo >&2
  echo "Dry run: $removed repo(s) matched. Re-run with --execute to delete." >&2
else
  echo >&2
  echo "Removed $removed repo(s)." >&2
fi
