#!/usr/bin/env bash
# Fails if anything that looks like a secret is about to be committed.
# Used by the pre-commit hook (tool/githooks/pre-commit) and by CI.
#   tool/check_secrets.sh          -> scans files staged for commit
#   tool/check_secrets.sh --all    -> scans every tracked file
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ "${1:-}" = "--all" ]; then
  files=$(git ls-files)
else
  files=$(git diff --cached --name-only --diff-filter=ACM)
fi
[ -z "$files" ] && exit 0

# Files that must never be tracked at all.
blocked=$(printf '%s\n' "$files" | grep -E '(^|/)(\.secret\.local|\.env(\..*)?|service-account.*\.json|.*-key\.json|.*\.pem|key\.properties)$' | grep -v '\.env\.example$' || true)
if [ -n "$blocked" ]; then
  echo "BLOCKED: secret files must not be committed:" >&2
  printf '  %s\n' $blocked >&2
  exit 1
fi

# Content patterns: Google API keys (AIza…, AQ.…), GitHub/OpenAI-style tokens, private keys.
pattern='(AIza[0-9A-Za-z_-]{35})|(AQ\.[0-9A-Za-z_-]{40,})|(gh[pousr]_[0-9A-Za-z]{30,})|(sk-[0-9A-Za-z]{32,})|(-----BEGIN [A-Z ]*PRIVATE KEY-----)'
hits=""
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in *.png|*.jpg|*.ttf|*.otf|*.pdf|*.ico|*.jar) continue;; esac
  if grep -nEI "$pattern" "$f" >/dev/null 2>&1; then hits="$hits $f"; fi
done <<< "$files"
if [ -n "$hits" ]; then
  echo "BLOCKED: possible secret found in:" >&2
  printf '  %s\n' $hits >&2
  echo "Move secrets to functions/.secret.local (git-ignored) or Firebase secrets." >&2
  exit 1
fi
echo "Secret check passed."
