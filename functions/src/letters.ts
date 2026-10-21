import { FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { bucket, db, requireId, requireUid, signedUrl } from './admin.js';
import { GEMINI_API_KEY, ENFORCE_APP_CHECK } from './config.js';
import { callGemini, type GeminiCaller } from './gemini.js';
import { fillLetter, LETTER_TEMPLATES, RECIPIENTS, type LetterDetails, type LetterTemplate } from './letterTemplates.js';
import { buildLetterPdf, formatDate } from './pdf.js';
import { isLanguage, type Language } from './shared.js';

const LANGUAGE_NAMES: Record<Language, string> = { az: 'Azerbaijani', ru: 'Russian', en: 'English' };

function text(v: unknown, max: number, required = false): string {
  const s = typeof v === 'string' ? v.trim() : '';
  if (required && !s) throw new HttpsError('invalid-argument', 'Missing required field.');
  if (s.length > max) throw new HttpsError('invalid-argument', 'Field too long.');
  return s;
}

/**
 * Optional AI polish. The facts the user typed (name, address, dates,
 * description words that are numbers) must survive verbatim; if Gemini drops
 * or changes any of them we keep the template version.
 */
export async function polishLetter(body: string, lang: Language, details: LetterDetails, gemini: GeminiCaller): Promise<string> {
  const polished = (await gemini({
    systemInstruction:
      `You improve the wording of formal letters in ${LANGUAGE_NAMES[lang]}. ` +
      'Make it polite, clear and concise. Do NOT add, remove or change any facts, names, addresses, dates, numbers, ' +
      'requests or deadlines. Do not add legal claims or law references. Keep the "To/From/Address/Date/Subject" lines ' +
      'exactly as they are. Return only the letter text.',
    text: body,
    temperature: 0.2,
  })).trim();
  const mustKeep = [details.name, details.address, details.since ?? '', ...(details.description.match(/\d[\d.,:/-]*/g) ?? [])]
    .map((s) => s.trim())
    .filter(Boolean);
  const keepsFacts = mustKeep.every((fact) => polished.includes(fact));
  if (!polished || !keepsFacts || polished.length > body.length * 2) {
    logger.info('letter polish rejected: facts changed or empty');
    return body;
  }
  return polished;
}

/**
 * generateLetter: fills the template from Firestore with the user's details,
 * optionally polishes it with Gemini (facts unchanged), stores the letter,
 * records it in the evidence log, and returns the text plus a PDF link.
 */
export const generateLetter = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK, secrets: [GEMINI_API_KEY], memory: '512MiB', timeoutSeconds: 90 },
  async (request) => {
    const uid = requireUid(request);
    const d = request.data ?? {};
    const homeId = requireId(d.homeId, 'homeId');
    const templateId = requireId(d.templateId, 'templateId');
    const recipient = typeof d.recipient === 'string' && d.recipient in RECIPIENTS ? d.recipient : 'other';
    const lang: Language = isLanguage(d.language) ? d.language : 'az';
    const details: LetterDetails = {
      name: text(d.details?.name, 120, true),
      address: text(d.details?.address, 300, true),
      recipientName: text(d.details?.recipientName, 120),
      description: text(d.details?.description, 1000, true),
      since: text(d.details?.since, 100),
    };

    const home = db().doc(`users/${uid}/homes/${homeId}`);
    if (!(await home.get()).exists) {
      // Letters can be written before anything else was saved.
      await home.set({}, { merge: true });
    }

    const stored = await db().doc(`letterTemplates/${templateId}`).get();
    const template = (stored.exists ? stored.data() : LETTER_TEMPLATES[templateId]) as LetterTemplate | undefined;
    if (!template?.subject?.[lang]) throw new HttpsError('not-found', 'Unknown letter template.');

    let body = fillLetter(template, lang, recipient, details, formatDate(new Date(), lang));
    if (d.polish === true) {
      try {
        body = await polishLetter(body, lang, details, callGemini);
      } catch (err) {
        logger.warn('letter polish failed, using template', { error: (err as Error).message });
      }
    }

    const letterRef = home.collection('letters').doc();
    const evidenceRef = home.collection('evidence').doc();
    const batch = db().batch();
    batch.set(letterRef, {
      templateId, recipient, language: lang, body, createdAt: FieldValue.serverTimestamp(),
    });
    // Hashed by onEvidenceCreated like any other evidence item.
    batch.set(evidenceRef, {
      type: 'letter', text: body, letterId: letterRef.id, deleted: false, createdAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();

    const pdfPath = `letters/${uid}/${letterRef.id}.pdf`;
    await bucket().file(pdfPath).save(await buildLetterPdf(lang, body), { contentType: 'application/pdf', resumable: false });
    return { letterId: letterRef.id, evidenceId: evidenceRef.id, body, pdfUrl: await signedUrl(pdfPath) };
  },
);
