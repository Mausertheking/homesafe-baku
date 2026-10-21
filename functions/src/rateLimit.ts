import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { TIME_ZONE } from './config.js';

/** Calendar day in Baku, e.g. "2026-10-18". */
export function bakuDay(now: Date): string {
  return new Intl.DateTimeFormat('en-CA', { timeZone: TIME_ZONE, year: 'numeric', month: '2-digit', day: '2-digit' }).format(now);
}

/**
 * Counts one use for this user today and throws resource-exhausted past the
 * limit. Stored in usage/{uid}_{day}, which clients cannot read or write.
 * Configure a Firestore TTL policy on usage.expiresAt to clean up.
 */
export async function consumeDailyQuota(db: Firestore, uid: string, limit: number, now = new Date()): Promise<number> {
  const day = bakuDay(now);
  const ref = db.doc(`usage/${uid}_${day}`);
  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const count = (snap.data()?.count as number | undefined) ?? 0;
    if (count >= limit) throw new HttpsError('resource-exhausted', 'Daily message limit reached.');
    tx.set(ref, {
      uid, day, count: count + 1,
      expiresAt: Timestamp.fromMillis(now.getTime() + 3 * 86_400_000),
    }, { merge: true });
    return count + 1;
  });
}
