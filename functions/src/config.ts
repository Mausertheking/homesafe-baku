import { defineSecret, defineString } from 'firebase-functions/params';

/** Must match functionsRegion in app/lib/core/callables.dart. */
export const REGION = 'europe-west1';
export const TIME_ZONE = 'Asia/Baku';

/**
 * Set with: firebase functions:secrets:set GEMINI_API_KEY
 * Only ever read inside askHomeSafe / generateLetter. Never logged or returned.
 */
export const GEMINI_API_KEY = defineSecret('GEMINI_API_KEY');

/**
 * Gemini model id, configured at deploy time (functions/.env or the deploy
 * prompt) rather than hard-coded in the logic. TODO(team): confirm the current
 * Flash model id before launch.
 */
export const GEMINI_MODEL = defineString('GEMINI_MODEL', {
  default: 'gemini-2.5-flash',
  description: 'Gemini Flash model id used by askHomeSafe and generateLetter',
});

export const CHAT_DAILY_LIMIT = 30;
export const MAX_MESSAGE_CHARS = 2000;
export const MAX_PHOTO_BYTES = 4 * 1024 * 1024;
export const SIGNED_URL_MINUTES = 15;

/**
 * App Check is enforced everywhere in production. Only the local Functions
 * emulator (used for the web preview and tests) skips it, because a local
 * browser cannot obtain App Check tokens. FUNCTIONS_EMULATOR is never set
 * when deploying or running in Cloud Functions.
 */
export const IN_EMULATOR = process.env.FUNCTIONS_EMULATOR === 'true';
export const ENFORCE_APP_CHECK = !IN_EMULATOR;
