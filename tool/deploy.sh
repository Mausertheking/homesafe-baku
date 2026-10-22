#!/usr/bin/env bash
# Deploys HomeSafe to a real Firebase project: security rules, Cloud
# Functions and the web app (Firebase Hosting, https://<project>.web.app).
#
#   tool/deploy.sh <firebase-project-id>
#
# Before the first run (see README "Setting up a real Firebase project"):
#   - you are logged in:            firebase login
#   - the Gemini key is a secret:   firebase functions:secrets:set GEMINI_API_KEY
# Optional: RECAPTCHA_SITE_KEY=... for App Check on the web. Without it the
# server is deployed with APP_CHECK_REQUIRED=false (team testing only).
set -euo pipefail
PROJECT="${1:?usage: tool/deploy.sh <firebase-project-id>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PATH="$ROOT/security-tests/node_modules/.bin:$HOME/development/flutter/bin:$PATH"

./tool/check_secrets.sh --all
./tool/sync_shared.sh >/dev/null

# Deploy-time params for this project (git-ignored file).
ENV_FILE="functions/.env.$PROJECT"
if [ -n "${RECAPTCHA_SITE_KEY:-}" ]; then APP_CHECK=true; else APP_CHECK=false; fi
{
  echo "GEMINI_MODEL=${GEMINI_MODEL:-gemini-2.5-flash}"
  echo "APP_CHECK_REQUIRED=$APP_CHECK"
} > "$ENV_FILE"
echo "App Check required on the server: $APP_CHECK"

(cd functions && npm ci --silent && npm run build)
(cd app && flutter build web --release ${RECAPTCHA_SITE_KEY:+--dart-define=RECAPTCHA_SITE_KEY=$RECAPTCHA_SITE_KEY})

firebase deploy --project "$PROJECT" --only firestore:rules,firestore:indexes,storage,functions,hosting
echo "Live: https://$PROJECT.web.app"
