#!/usr/bin/env bash
# Copies the shared source-of-truth files into the app bundle and the
# functions package. Run after editing anything in shared/.
# The app test "bundled copies match shared/" fails if you forget.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
node "$ROOT/shared/rules/build_rules.mjs"
cp "$ROOT"/shared/rules/gas_co.json "$ROOT"/shared/rules/damp_mold.json "$ROOT/app/assets/rules/"
cp "$ROOT/shared/emergency_keywords.json" "$ROOT/app/assets/config/"
mkdir -p "$ROOT/functions/shared/rules"
cp "$ROOT"/shared/rules/gas_co.json "$ROOT"/shared/rules/damp_mold.json "$ROOT/functions/shared/rules/"
cp "$ROOT/shared/emergency_keywords.json" "$ROOT/shared/emergency_keyword_cases.json" "$ROOT/app/assets/config/emergency.json" "$ROOT/functions/shared/"
cp "$ROOT/homesafe-gemini-system-prompt.md" "$ROOT/functions/shared/"
# The server renders PDFs and push messages with the app's own translations.
mkdir -p "$ROOT/functions/shared/l10n"
cp "$ROOT"/app/lib/l10n/app_*.arb "$ROOT"/app/assets/l10n/content_*.arb "$ROOT/functions/shared/l10n/"
# Draft legal topics: shown offline in the app, seeded into Firestore by functions.
mkdir -p "$ROOT/app/assets/legal" "$ROOT/functions/shared/legal"
cp "$ROOT/shared/legal/rights.json" "$ROOT/app/assets/legal/"
cp "$ROOT/shared/legal/rights.json" "$ROOT/functions/shared/legal/"
echo "Shared files synced."
