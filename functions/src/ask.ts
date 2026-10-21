import { FieldValue, type Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { db, requireId, requireUid } from './admin.js';
import { CHAT_DAILY_LIMIT, GEMINI_API_KEY, GEMINI_MODEL, MAX_MESSAGE_CHARS, MAX_PHOTO_BYTES, ENFORCE_APP_CHECK } from './config.js';
import { emergencyDetector } from './emergency.js';
import { callGemini, type GeminiCaller } from './gemini.js';
import { strings } from './i18n.js';
import { formatDate } from './pdf.js';
import { fillPrompt, loadPromptTemplate } from './prompt.js';
import { consumeDailyQuota } from './rateLimit.js';
import { ruleFiles } from './rules.js';
import { isLanguage, readSharedJson, type Language } from './shared.js';

const EMERGENCY_TAG = '[[EMERGENCY]]';
const OFF_TOPIC_TAG = '[[OFF_TOPIC]]';

/**
 * Turns the raw model output into what the app shows. If the model flagged
 * the request as off-topic, the user gets a fixed, translated refusal: the
 * model's own text is never shown, so it cannot half-answer (e.g. code).
 */
export function finalizeAnswer(raw: string, lang: Language): { answer: string; mentionsEmergency: boolean; offTopic: boolean } {
  if (raw.includes(OFF_TOPIC_TAG) || raw.trim() === '') {
    return { answer: strings(lang)('chat.off_topic'), mentionsEmergency: false, offTopic: true };
  }
  return {
    answer: toPlainText(raw.replaceAll(EMERGENCY_TAG, '')),
    mentionsEmergency: raw.includes(EMERGENCY_TAG),
    offTopic: false,
  };
}

/** The app shows plain text; remove Markdown the model may still produce. */
export function toPlainText(text: string): string {
  return text
    .replace(/\*\*(.+?)\*\*/g, '$1')
    .replace(/__(.+?)__/g, '$1')
    .replace(/^#{1,6}\s+/gm, '')
    .replace(/^\s*[*-]\s+/gm, '• ')
    .replace(/`([^`]+)`/g, '$1')
    .replace(/\n{3,}/g, '\n\n')
    .trim();
}
const LANGUAGE_NAMES: Record<Language, string> = { az: 'Azerbaijani (Azərbaycan dili)', ru: 'Russian (русский)', en: 'English' };
const PHOTO_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

export interface AskInput {
  uid: string;
  homeId: string;
  message: string;
  language: Language;
  photo: { mimeType: string; data: string } | null;
}

export interface AskResult {
  emergency: boolean;
  answer: string | null;
  mentionsEmergency: boolean;
}

export function parseAskInput(uid: string, data: unknown): AskInput {
  const d = (data ?? {}) as Record<string, unknown>;
  const message = typeof d.message === 'string' ? d.message.trim() : '';
  if (!message || message.length > MAX_MESSAGE_CHARS) throw new HttpsError('invalid-argument', 'Message is empty or too long.');
  let photo: AskInput['photo'] = null;
  if (d.photo != null) {
    const p = d.photo as Record<string, unknown>;
    if (typeof p.data !== 'string' || typeof p.mimeType !== 'string' || !PHOTO_TYPES.includes(p.mimeType)) {
      throw new HttpsError('invalid-argument', 'Invalid photo.');
    }
    if ((p.data.length * 3) / 4 > MAX_PHOTO_BYTES) throw new HttpsError('invalid-argument', 'Photo too large.');
    photo = { mimeType: p.mimeType, data: p.data };
  }
  return {
    uid,
    homeId: requireId(d.homeId, 'homeId'),
    message,
    language: isLanguage(d.language) ? d.language : 'az',
    photo,
  };
}

/** Builds the context placeholders from the user's own data only. */
export async function buildContext(firestore: Firestore, input: AskInput) {
  const home = firestore.doc(`users/${input.uid}/homes/${input.homeId}`);
  const [homeSnap, userSnap, latestSnap, topicsSnap, configSnap] = await Promise.all([
    home.get(),
    firestore.doc(`users/${input.uid}`).get(),
    home.collection('checks').orderBy('createdAt', 'desc').limit(1).get(),
    firestore.collection('legalTopics').get(),
    firestore.doc('config/app').get(),
  ]);

  // Only facts, no personal data (no names, phone numbers or addresses).
  const h = homeSnap.data() ?? {};
  const profile = {
    role: userSnap.data()?.role ?? 'unknown',
    district: h.district ?? 'unknown',
    buildingAgeBand: h.buildingAgeBand ?? 'unknown',
    heatingType: h.heatingType ?? 'unknown',
    gasWaterHeaterLocation: h.heaterLocation ?? 'unknown',
    hasCoAlarm: h.hasCoAlarm ?? 'unknown',
    hasWrittenContract: h.hasWrittenContract ?? 'unknown',
  };

  const latest = latestSnap.docs[0]?.data();
  const latestCheck = latest
    ? JSON.stringify({
        check: latest.hazard, level: latest.resultLevel, matchedRuleIds: latest.matchedRuleIds,
        date: latest.createdAt?.toDate?.().toISOString().slice(0, 10),
      })
    : 'No check saved yet.';

  // Rules matched by the latest check first, then every red/emergency rule,
  // summarised as id, level and the English reason so the model has context.
  const en = readSharedJson<Record<string, string>>('l10n', 'content_en.arb');
  const matched = new Set<string>(Array.isArray(latest?.matchedRuleIds) ? latest!.matchedRuleIds : []);
  const relevant = ruleFiles().flatMap((f) => f.rules)
    .filter((r) => matched.has(r.id) || r.result.level === 'red')
    .map((r) => `- ${r.id} [${r.result.level}${r.reviewed ? '' : ', unreviewed'}]: ${en[r.result.reason_key] ?? r.result.reason_key}`)
    .join('\n');

  const lang = input.language;
  const topics = topicsSnap.docs
    .map((d) => d.data())
    .filter((t) => t.reviewedBy && t.reviewedOn && t.body?.[lang]) // Lawyer-reviewed only.
    .map((t) => `### ${t.title?.[lang] ?? ''}\n${t.body[lang]}\nLaw: ${t.lawReference?.[lang] ?? '-'}\nReviewed by ${t.reviewedBy} on ${t.reviewedOn}`)
    .join('\n\n');

  const numbers = (configSnap.data()?.emergencyNumbers as { id: string; number: string }[] | undefined) ??
    readSharedJson<{ numbers: { id: string; number: string }[] }>('emergency.json').numbers;

  return {
    CURRENT_DATE: formatDate(new Date(), 'en'),
    LANGUAGE: LANGUAGE_NAMES[lang],
    EMERGENCY_NUMBERS: numbers.map((n) => `${n.id}: ${n.number}`).join(', '),
    HOME_PROFILE: JSON.stringify(profile),
    LATEST_CHECK: latestCheck,
    RELEVANT_RULES: relevant || 'None.',
    LEGAL_TOPICS: topics || 'No reviewed legal topics yet. Do not answer legal details; suggest asking a lawyer.',
  };
}

/** Core logic, separated from the trigger so it can be tested with a fake Gemini. */
export async function askHomeSafeCore(firestore: Firestore, input: AskInput, gemini: GeminiCaller): Promise<AskResult> {
  const started = Date.now();
  const log = (fields: Record<string, unknown>) =>
    // Abuse monitoring: METADATA ONLY. Never the message, photo or answer.
    firestore.collection('abuseLog').add({
      uid: input.uid, at: FieldValue.serverTimestamp(), language: input.language,
      messageLength: input.message.length, hasPhoto: input.photo != null, ...fields,
    }).catch((e) => logger.warn('abuse log failed', { error: (e as Error).message }));

  // 1. Same emergency check as the app, BEFORE Gemini and before the quota.
  if (emergencyDetector().isEmergency(input.message)) {
    await log({ outcome: 'emergency_keyword' });
    return { emergency: true, answer: null, mentionsEmergency: true };
  }

  // 2. Rate limit: 30 messages per user per day.
  try {
    await consumeDailyQuota(firestore, input.uid, CHAT_DAILY_LIMIT);
  } catch (e) {
    await log({ outcome: 'rate_limited' });
    throw e;
  }

  // 3. Context + system prompt.
  const systemInstruction = fillPrompt(loadPromptTemplate(), await buildContext(firestore, input));

  // 4. Gemini.
  let raw: string;
  try {
    raw = await gemini({ systemInstruction, text: input.message, photo: input.photo });
  } catch (e) {
    await log({ outcome: 'model_error', latencyMs: Date.now() - started });
    logger.error('gemini call failed', { error: (e as Error).message });
    throw new HttpsError('unavailable', 'Assistant unavailable.');
  }

  const { answer, mentionsEmergency, offTopic } = finalizeAnswer(raw, input.language);
  if (offTopic) {
    await log({ outcome: 'off_topic', latencyMs: Date.now() - started });
    return { emergency: false, answer, mentionsEmergency: false };
  }
  await log({ outcome: 'answered', mentionsEmergency, latencyMs: Date.now() - started, answerLength: answer.length });
  return { emergency: false, answer, mentionsEmergency };
}

export const askHomeSafe = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK, consumeAppCheckToken: ENFORCE_APP_CHECK, secrets: [GEMINI_API_KEY], memory: '512MiB', timeoutSeconds: 60 },
  async (request) => {
    const uid = requireUid(request);
    const input = parseAskInput(uid, request.data);
    logger.info('askHomeSafe', { model: GEMINI_MODEL.value(), language: input.language, hasPhoto: !!input.photo });
    return askHomeSafeCore(db(), input, callGemini);
  },
);
