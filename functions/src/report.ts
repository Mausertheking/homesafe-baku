import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { bucket, db, requireId, requireUid, signedUrl } from './admin.js';
import { ENFORCE_APP_CHECK } from './config.js';
import { buildReportPdf, type ReportCheck, type ReportEvidence } from './pdf.js';
import { ruleById } from './rules.js';
import { isLanguage } from './shared.js';

const MAX_PHOTOS = 40;
const MAX_RANGE_DAYS = 3 * 366;

function parseDate(v: unknown, name: string): Date {
  const d = typeof v === 'string' ? new Date(v) : new Date(NaN);
  if (Number.isNaN(d.getTime())) throw new HttpsError('invalid-argument', `${name} must be an ISO date.`);
  return d;
}

/**
 * generateReport: builds a PDF for a date range (home profile, check results,
 * evidence with photos, server times and hashes, and an explanation of the
 * hashes) and returns a 15-minute signed link. Deleted evidence is left out.
 */
export const generateReport = onCall(
  { enforceAppCheck: ENFORCE_APP_CHECK, memory: '1GiB', timeoutSeconds: 120 },
  async (request) => {
    const uid = requireUid(request);
    const homeId = requireId(request.data?.homeId, 'homeId');
    const lang = isLanguage(request.data?.language) ? request.data.language : 'az';
    const from = parseDate(request.data?.from, 'from');
    const to = parseDate(request.data?.to, 'to');
    if (to < from || (to.getTime() - from.getTime()) / 86_400_000 > MAX_RANGE_DAYS) {
      throw new HttpsError('invalid-argument', 'Invalid date range.');
    }

    const home = db().doc(`users/${uid}/homes/${homeId}`);
    const [homeSnap, userSnap, checksSnap, evidenceSnap] = await Promise.all([
      home.get(),
      db().doc(`users/${uid}`).get(),
      home.collection('checks').where('createdAt', '>=', Timestamp.fromDate(from))
        .where('createdAt', '<=', Timestamp.fromDate(to)).orderBy('createdAt').get(),
      home.collection('evidence').where('createdAt', '>=', Timestamp.fromDate(from))
        .where('createdAt', '<=', Timestamp.fromDate(to)).orderBy('createdAt').get(),
    ]);
    if (!homeSnap.exists) throw new HttpsError('not-found', 'Home not found.');

    const checks: ReportCheck[] = checksSnap.docs.map((d) => {
      const c = d.data();
      const ids: string[] = Array.isArray(c.matchedRuleIds) ? c.matchedRuleIds : [];
      const reasonKeys = ids.map((id) => ruleById(id)?.result.reason_key).filter((k): k is string => !!k);
      return {
        hazard: String(c.hazard),
        resultLevel: String(c.resultLevel),
        matchedRuleIds: ids,
        reasonKeys: reasonKeys.length ? reasonKeys : ['rule.default.reason'],
        rulesVersion: Number(c.rulesVersion ?? 0),
        createdAt: (c.createdAt as Timestamp).toDate(),
      };
    });

    let photos = 0;
    const evidence: ReportEvidence[] = [];
    for (const d of evidenceSnap.docs) {
      const e = d.data();
      if (e.deleted === true) continue;
      let photo: Buffer | null = null;
      if (typeof e.storagePath === 'string' && e.storagePath.startsWith(`users/${uid}/`) && photos < MAX_PHOTOS) {
        try {
          [photo] = await bucket().file(e.storagePath).download();
          photos++;
        } catch (err) {
          logger.warn('report: photo missing', { item: d.id, error: (err as Error).message });
        }
      }
      evidence.push({
        id: d.id,
        type: String(e.type),
        // Check items hold a machine summary; the check section shows them in full.
        text: e.type === 'check' ? '' : String(e.text ?? ''),
        sha256: e.sha256 ?? null,
        serverTime: e.serverTime ? (e.serverTime as Timestamp).toDate() : null,
        photo,
      });
    }

    const pdf = await buildReportPdf({
      lang,
      generatedAt: new Date(),
      from,
      to,
      profile: { ...homeSnap.data(), role: userSnap.data()?.role ?? null },
      checks,
      evidence,
    });

    const path = `reports/${uid}/${Date.now()}.pdf`;
    await bucket().file(path).save(pdf, { contentType: 'application/pdf', resumable: false });
    return { url: await signedUrl(path) };
  },
);
