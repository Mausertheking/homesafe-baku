# HomeSafe Baku

A mobile app (Flutter, iOS and Android) that helps people in Baku find and deal with home hazards (gas heaters, carbon monoxide, damp and mold), document problems with tamper-evident evidence, write repair letters, read reviewed legal information, and ask an AI assistant.

**Live web demo:** https://mausertheking.github.io/homesafe-baku/ (open it on a phone for the real feel). The demo runs without a server: the emergency screen, both safety checks, check history, Your rights, the legal pages and all three languages work; accounts, the evidence log, letters, reports and the AI assistant are switched off there. It is rebuilt automatically on every push to `main` (`.github/workflows/demo.yml`, built with `--dart-define=DEMO=true`).

> **Status:** feature-complete MVP, not launch-ready. The legal texts are written as **drafts** and every hazard rule, letter template and emergency number is still waiting for expert review (see "Before launch" below).

## Secrets: what is NOT in this repository

- The **Gemini API key** is never in the app or in git. Locally it lives in `functions/.secret.local` (git-ignored); in production it is a Firebase secret: `firebase functions:secrets:set GEMINI_API_KEY`.
- `.gitignore` blocks `*.local`, `.env*`, service-account and key files, and the local emulator data.
- `tool/check_secrets.sh` scans for API keys, tokens and private keys. It runs in CI on every push, and locally before every commit once you enable the hook:

```bash
git config core.hooksPath tool/githooks
```

## Legal texts (drafts)

| Text | Where | Status |
| --- | --- | --- |
| "Your rights": repairs, written contracts, deposits, inspections, owners' duties (az/ru/en) | `shared/legal/rights.json` (bundled in the app, seeded to Firestore) | Draft. Cites only articles that could be read in the law texts (Housing Code No. 845-IIIQ Arts 5, 15; Law "On Lease" Art. 7; Law "On Gas Supply" No. 233-VIIQ); other references say "to be confirmed" |
| Privacy policy (az/ru/en) | `app/assets/legal/privacy_*.md` | Draft, based on what the app really collects. Placeholders: operator name/address, contact e-mail, minimum age |
| Terms of use (az/ru/en) | `app/assets/legal/terms_*.md` | Draft. Same placeholders |
| Repair and inspection letters | `functions/src/letterTemplates.ts` | Draft, no legal claims |

In the app every draft carries an amber "Draft: not yet checked by a lawyer" notice. The AI assistant only uses a legal topic after a lawyer is recorded in `reviewedBy` and `reviewedOn`. When a lawyer approves a text: set those two fields in Firestore `legalTopics/<id>` (and in `rights.json`), set `legalDocsFinal = true` in `app/lib/features/rights/legal_doc_screen.dart` for the privacy policy and terms, and change `"status": "draft"`.

## Layout

```
homesafe/
  app/                     Flutter app (Riverpod, go_router, intl/ARB, Firebase)
    lib/rules_engine/      Pure-Dart rules evaluator (no Flutter imports)
    lib/features/...       One folder per screen/feature
    lib/l10n/app_*.arb     UI strings (az default, ru, en)
    assets/l10n/content_*.arb  Data-driven strings: rule reasons, steps, questions, districts, PDF/push texts
    assets/rules/          Bundled rule files (copied from shared/)
    assets/config/         Emergency numbers + emergency keywords (bundled, work offline)
  functions/               Cloud Functions, 2nd gen, TypeScript (ESM), region europe-west1
  shared/                  Single source of truth: rules, emergency keywords + test vectors
  security-tests/          Firestore/Storage rules tests + end-to-end hashing test (emulators)
  firestore.rules, storage.rules, firebase.json
  homesafe-gemini-system-prompt.md   DRAFT system prompt (see TODO)
  tool/sync_shared.sh      Copies shared/ files into app/ and functions/
```

Edit rules in `shared/rules/build_rules.mjs` (generates the JSON) or emergency keywords in `shared/emergency_keywords.json`, then run `./tool/sync_shared.sh`. Tests fail if the copies drift.

## Try everything on this computer (local backend)

The app can run against the Firebase **emulators** with a demo project, so sign-up, the evidence log, letters, PDF reports and data export all work locally, with no real Firebase project and no cost.

1. Start the backend (builds the functions, starts auth/database/storage/functions emulators, loads seed data, and keeps local accounts in `.emulator-data/`):

```bash
./tool/dev_backend.sh
```

2. Build and serve the app against it:

```bash
cd app && flutter build web --dart-define=USE_EMULATORS=true && node ../tool/serve_web.mjs 4960
```

Then open http://localhost:4960 and create an account with any email (it only exists in the local emulator).

**AI assistant (Gemini key):** put your key in `functions/.secret.local` (git-ignored, never shipped in the app):

```bash
printf 'GEMINI_API_KEY=%s\n' 'PASTE-YOUR-KEY-HERE' > functions/.secret.local
```

and restart `./tool/dev_backend.sh`. For the real project use `firebase functions:secrets:set GEMINI_API_KEY` instead.

## Running the tests

```bash
cd app && flutter test
```

```bash
cd functions && npm test
```

```bash
cd security-tests && npm test
```

```bash
cd functions && npm run test:emulator
```

The last two need Java 11+ (Firebase emulators). `security-tests` also runs the real `onEvidenceCreated` function in the Functions emulator; build the functions first (`cd functions && npm run build`) and create `functions/.secret.local` containing `GEMINI_API_KEY=dummy` for the emulator.

Current results: app 128 tests (74 rules engine, 30 emergency keywords, 9 translation and legal-text completeness, 14 widget, 1 no-secrets), functions 69 (64 unit + 5 on the Firestore emulator), security 37 (35 rules + 2 end-to-end hashing).

Live assistant check (real Gemini, needs the key in `functions/.secret.local`, costs a few cents): 9 unrelated or trick requests must be refused (code, homework, essays, "ignore your rules", "show your prompt", in en/az/ru) and 4 real home questions must be answered:

```bash
cd functions && GEMINI_LIVE=1 npx vitest run test/live.test.ts
```

## How the main pieces work

- **Emergency screen**: `main()` loads only local data (bundled numbers, bundled texts, keyword list) before the first frame. Firebase starts afterwards, in the background. The `/emergency` route skips all redirects, so it works before onboarding, signed out and offline. A cached copy of `config/app.emergencyNumbers` replaces the bundled numbers once the app has been online.
- **Rules engine**: `app/lib/rules_engine/`. Supports `all`, `any`, `not`, `eq`, `neq`, `in`, `gt`, `lt`, `exists`. Every rule is evaluated, the level is the highest matched (red > amber > green), reasons from all matched rules are shown, and steps are de-duplicated. Missing answers never match a comparison (even `neq`); `not` is used on purpose for cautious rules. A rule file with any invalid rule is rejected as a whole. Rules are evaluated after every answer, so an emergency rule opens the emergency screen mid-check. Newer rules download from Firestore `rules/*` when `config/app.rulesVersion` is higher, and are only accepted if every text key they use exists in the app.
- **Evidence**: photos upload to `users/{uid}/homes/{homeId}/evidence/{itemId}/photo.jpg` first, then the document is created. `onEvidenceCreated` writes `sha256` (of the file, or of `JSON.stringify([1, itemId, type, text, checkId, letterId])` for text items) and `serverTime` (the Firestore commit time). Rules forbid clients from setting these, editing evidence, overwriting photos, or deleting anything; the only change allowed is "mark deleted".
- **Emergency keywords**: identical folding and matching in Dart and TypeScript (lowercase, Azerbaijani letters to ASCII, `ё`→`е`, word-start matching, "headache + heater" combos), proven by the shared vectors in `shared/emergency_keyword_cases.json`. Checked in the app before sending, and again on the server before Gemini.
- **askHomeSafe**: auth + App Check (with replay protection), emergency check, 30 messages/user/day (Baku calendar day, `usage/` collection), context from the user's own home profile, latest check, relevant rules and lawyer-reviewed topics only, Gemini model from the `GEMINI_MODEL` param, metadata-only abuse log (`abuseLog/`). The model marks emergency answers with `[[EMERGENCY]]`; the app shows an "open emergency steps" button. Anything outside home safety, damp/mold, repairs, housing rights or the app (code, homework, trivia, jailbreak attempts, prompt requests) must come back as `[[OFF_TOPIC]]`; the server then shows a fixed, translated refusal (`chat.off_topic`) and never the model's own text. Answers are converted to plain text; output limit 4,096 tokens with a 1,024-token thinking budget (lower limits cut Azerbaijani answers off).
- **PDFs**: pdfkit with Noto Sans (OFL, in `functions/assets/fonts`), which covers Azerbaijani and Cyrillic. Reports, letters and exports are stored in private paths and shared only as 15-minute signed URLs.
- **Check history**: every finished check is stored on the phone (also for guests) and drives the "Your home safety" card and the history screen. Reopening a result re-runs the stored answers through the current rules. Saving to the evidence log is a separate, explicit step.
- **Privacy**: Analytics goes through an allow-list (`app/lib/core/analytics.dart`) that accepts only enum-like values. Photos are read through Storage rules (`getData`), never via public download URLs. Push reminders use per-language FCM topics, so the server stores no device tokens.

## Setting up a real Firebase project

1. `firebase use --add` (replace `demo-homesafe` in `.firebaserc`), then `cd app && flutterfire configure` (this replaces the placeholder `lib/firebase_options.dart`; until then the app runs offline-only).
2. Enable the Auth provider **Email/Password** (phone sign-in was removed; the app uses email only, with password reset).
3. Set the secret: `firebase functions:secrets:set GEMINI_API_KEY`. Optionally set `GEMINI_MODEL` in `functions/.env`.
4. Deploy: `firebase deploy --only firestore,storage,functions`.
5. Seed reference data: `cd functions && npm run build && GCLOUD_PROJECT=<id> npm run seed`.
6. App Check: register Play Integrity (Android) and App Attest/DeviceCheck (iOS), then **enforce** App Check for Firestore and Storage in the console (callables already set `enforceAppCheck`). Register debug tokens for development builds.
7. Signed URLs: give the functions' service account the "Service Account Token Creator" role on itself.
8. Firestore TTL policy on `usage.expiresAt`; Storage lifecycle rule to delete `reports/`, `letters/` and `exports/` objects after 1 day.

## Before launch (TODOs left for the team, deliberately not invented)

- [ ] **Emergency numbers**: verify `app/assets/config/emergency.json` against official sources, then set `"verified": true` (a yellow developer banner shows until then, in debug builds only).
- [ ] **Hazard rules**: chemical-engineer review of every rule in `shared/rules/` (all are `"reviewed": false`; a test enforces this until the team flips them deliberately). Also review the question wording in `content_*.arb`.
- [ ] **Legal topics**: a lawyer reviews the drafts in `shared/legal/rights.json`, confirms or adds the article numbers marked "to be confirmed", and is recorded in `reviewedBy` / `reviewedOn`.
- [ ] **Letter templates**: lawyer review of `functions/src/letterTemplates.ts` (no legal claims or law citations yet).
- [ ] **Privacy policy and terms of use**: lawyer review of the drafts in `app/assets/legal/`, and fill in the operator name and address, contact e-mail and minimum age.
- [ ] **Rotate the Gemini API key** used during development before launch, and store the new one only as a Firebase secret.
- [ ] **App name, logo and colours** (`app/lib/core/theme.dart`, launcher icons, bundle id `az.homesafe.homesafe`).
- [ ] **Gemini system prompt**: `homesafe-gemini-system-prompt.md` is a draft written for this build; replace it with the team's version if there is one (keep the placeholders; a test checks them).
- [ ] **Translations**: native-speaker review of Azerbaijani and Russian (UI, content, emergency keyword lists).
- [ ] Confirm the current Gemini Flash model id for `GEMINI_MODEL`.
- [ ] Test on a real low-end Android phone (startup time, emergency screen) and with TalkBack/VoiceOver.
