import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

import { bucket } from './admin.js';
import { HASH_VERSION, sha256Stream, sha256Text } from './hash.js';

const MAX_ATTEMPTS = 5;

/**
 * onEvidenceCreated: computes the SHA-256 of the uploaded photo (or of the
 * canonical text for notes, symptoms, checks and letters) and stores it with
 * the server time. Clients can never write sha256/serverTime (security rules),
 * and evidence can never be edited afterwards, so the pair proves what
 * existed and when.
 */
export const onEvidenceCreated = onDocumentCreated(
  { document: 'users/{uid}/homes/{homeId}/evidence/{itemId}', retry: false, memory: '512MiB' },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const data = snap.data();
    if (data.sha256) return; // Already hashed (idempotent on redelivery).
    const { uid, homeId, itemId } = event.params;

    // createTime is set by Firestore itself when the document was committed:
    // the most trustworthy "when" we have.
    const serverTime: Timestamp = snap.createTime ?? Timestamp.now();
    const update: Record<string, unknown> = { serverTime, hashVersion: HASH_VERSION, hashedAt: FieldValue.serverTimestamp() };

    try {
      if (typeof data.storagePath === 'string' && data.storagePath) {
        const expectedPrefix = `users/${uid}/homes/${homeId}/evidence/${itemId}/`;
        if (!data.storagePath.startsWith(expectedPrefix)) {
          // Security rules prevent this; never hash a file from someone else's folder.
          logger.warn('evidence storagePath outside its folder', { itemId });
          await snap.ref.update({ hashError: 'bad_path' });
          return;
        }
        const file = bucket().file(data.storagePath);
        const { sha256, size } = await withRetry(async () => {
          const [exists] = await file.exists();
          if (!exists) throw new Error('file not uploaded yet');
          return sha256Stream(file.createReadStream());
        });
        Object.assign(update, { sha256, fileSize: size });
      } else {
        update.sha256 = sha256Text({
          itemId,
          type: String(data.type ?? ''),
          text: String(data.text ?? ''),
          checkId: (data.checkId as string | undefined) ?? null,
          letterId: (data.letterId as string | undefined) ?? null,
        });
      }
      await snap.ref.update(update);
    } catch (err) {
      logger.error('evidence hashing failed', { itemId, error: (err as Error).message });
      await snap.ref.update({ hashError: 'failed' }).catch(() => undefined); // Doc may be gone (tests).
    }
  },
);

async function withRetry<T>(fn: () => Promise<T>): Promise<T> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      await new Promise((r) => setTimeout(r, 500 * attempt));
    }
  }
  throw lastError;
}
