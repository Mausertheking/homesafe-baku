import { getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';

import { randomUUID } from 'node:crypto';

import { IN_EMULATOR, SIGNED_URL_MINUTES } from './config.js';

if (getApps().length === 0) initializeApp();

export const db = () => getFirestore();
export const bucket = () => getStorage().bucket();
export const auth = () => getAuth();
export const messaging = () => getMessaging();

/** Callable guard: signed-in user required. App Check is enforced per function. */
export function requireUid(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in required.');
  return uid;
}

/** Firestore ids we generate are [A-Za-z0-9]{20}; accept a little more. */
export function requireId(value: unknown, name: string): string {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,64}$/.test(value)) {
    throw new HttpsError('invalid-argument', `${name} is invalid.`);
  }
  return value;
}

/**
 * Read link for a private file (reports, letters, exports).
 * Preferred: a V4 signed URL valid for 15 minutes. That needs the functions'
 * service account to have "Service Account Token Creator" on itself; until
 * someone grants it (and in the emulator) we fall back to a private download
 * token. Either way the file is deleted after a day by cleanupTempFiles.
 */
export async function signedUrl(path: string): Promise<string> {
  const file = bucket().file(path);
  if (!IN_EMULATOR) {
    try {
      const [url] = await file.getSignedUrl({
        action: 'read', version: 'v4', expires: Date.now() + SIGNED_URL_MINUTES * 60 * 1000,
      });
      return url;
    } catch (err) {
      logger.warn('signed URL unavailable, using a download token', { error: (err as Error).message });
    }
  }
  const token = randomUUID();
  await file.setMetadata({ metadata: { firebaseStorageDownloadTokens: token } });
  const base = IN_EMULATOR
    ? `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST ?? '127.0.0.1:9199'}`
    : 'https://firebasestorage.googleapis.com';
  return `${base}/v0/b/${bucket().name}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}
