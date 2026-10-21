#!/usr/bin/env bash
# Starts the full HomeSafe backend LOCALLY (Firebase emulators: auth,
# firestore, storage, functions) with seed data, for trying the app on this
# computer. Nothing here talks to real Firebase (project id demo-homesafe).
#
# The AI assistant needs a real Gemini key in functions/.secret.local:
#   GEMINI_API_KEY=your-key
# Without it, chat answers fail but everything else works.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export JAVA_HOME="${JAVA_HOME:-$HOME/development/jdk/jdk-21.0.12.1+1/Contents/Home}"
export PATH="$JAVA_HOME/bin:$ROOT/security-tests/node_modules/.bin:$PATH"

# Refuse to start if an old emulator still holds the ports (seed would go to it).
for port in 4400 5001 8080 9099 9199; do
  if lsof -nP -iTCP:$port -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Port $port is already in use (an old emulator?). Stop it first, e.g.: lsof -ti tcp:$port | xargs kill" >&2
    exit 1
  fi
done

./tool/sync_shared.sh >/dev/null
(cd functions && npm run build >/dev/null)
[ -f functions/.secret.local ] || printf 'GEMINI_API_KEY=not-set\n' > functions/.secret.local

# Keep local accounts and data between restarts (in .emulator-data/, git-ignored).
IMPORT=()
[ -f .emulator-data/firebase-export-metadata.json ] && IMPORT=(--import=.emulator-data)
firebase emulators:start --project demo-homesafe --only auth,firestore,storage,functions \
  ${IMPORT[@]+"${IMPORT[@]}"} --export-on-exit=.emulator-data &
EMU=$!
# Stop the whole process group (the Java emulators too) when this script ends.
trap 'trap - EXIT INT TERM; kill 0 2>/dev/null' EXIT INT TERM

# Wait for Firestore, then load rules, legal topic placeholders, templates, config.
for _ in $(seq 1 120); do
  curl -s -o /dev/null http://127.0.0.1:8080 && break
  sleep 1
done
(cd functions && FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=demo-homesafe node lib/scripts/seed.js)
echo "HomeSafe local backend ready."
wait $EMU
