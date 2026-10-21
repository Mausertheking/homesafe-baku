import { PassThrough } from 'node:stream';

import { ZipArchive } from 'archiver';
import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';

import { ENFORCE_APP_CHECK } from './config.js';
import { auth, bucket, db, requireUid, signedUrl } from './admin.js';

/** Storage prefixes that hold a user's files. */
export const userPrefixes = (uid: string) => [`users/${uid}/`, `reports/${uid}/`, `letters/${uid}/`, `exports/${uid}/`];

/** Recursively reads a document and all subcollections into plain JSON. */
export async function dumpDocument(ref: DocumentReference): Promise<Record<string, unknown>> {
  const snap = await ref.get();
  const out: Record<string, unknown> = { id: ref.id, data: snap.exists ? toJson(snap.data()) : null };
  const collections = await ref.listCollections();
  for (const col of collections) {
    const docs = await col.listDocuments();
    out[col.id] = await Promise.all(docs.map(dumpDocument));
  }
  return out;
}

function toJson(value: unknown): unknown {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (Array.isArray(value)) return value.map(toJson);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, toJson(v)]));
  }
  return value;
}

/**
 * exportMyData: everything we hold about the user as a ZIP (data.json plus
 * every uploaded photo), returned as a 15-minute signed link.
 */
export const exportMyData = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, memory: '1GiB', timeoutSeconds: 300 }, async (request) => {
  const uid = requireUid(request);
  const data = {
    exportedAt: new Date().toISOString(),
    account: await auth().getUser(uid).then((u) => ({ uid: u.uid, email: u.email ?? null, phoneNumber: u.phoneNumber ?? null, createdAt: u.metadata.creationTime })),
    user: await dumpDocument(db().doc(`users/${uid}`)),
  };

  // Remove older exports first so only one copy ever exists.
  await bucket().deleteFiles({ prefix: `exports/${uid}/` });

  const path = `exports/${uid}/homesafe-export-${Date.now()}.zip`;
  const zip = new ZipArchive({ zlib: { level: 9 } });
  const upload = bucket().file(path).createWriteStream({ contentType: 'application/zip', resumable: false });
  const pass = new PassThrough();
  const done = new Promise<void>((resolve, reject) => {
    upload.on('finish', () => resolve());
    upload.on('error', reject);
    zip.on('error', reject);
  });
  zip.pipe(pass).pipe(upload);

  zip.append(JSON.stringify(data, null, 2), { name: 'data.json' });
  const [files] = await bucket().getFiles({ prefix: `users/${uid}/` });
  for (const f of files) zip.append(f.createReadStream(), { name: `files/${f.name.slice(`users/${uid}/`.length)}` });
  await zip.finalize();
  await done;
  return { url: await signedUrl(path) };
});

/** Deletes every trace of the user. Exported for the emulator test. */
export async function deleteUserData(firestore: Firestore, uid: string): Promise<void> {
  await firestore.recursiveDelete(firestore.doc(`users/${uid}`));
  for (const col of ['usage', 'abuseLog']) {
    const docs = await firestore.collection(col).where('uid', '==', uid).get();
    const writer = firestore.bulkWriter();
    docs.forEach((d) => void writer.delete(d.ref));
    await writer.close();
  }
}

/** deleteMyAccount: removes all Firestore data, all files and the account. */
export const deleteMyAccount = onCall({ enforceAppCheck: ENFORCE_APP_CHECK, timeoutSeconds: 300 }, async (request) => {
  const uid = requireUid(request);
  await deleteUserData(db(), uid);
  for (const prefix of userPrefixes(uid)) await bucket().deleteFiles({ prefix });
  await auth().deleteUser(uid);
  logger.info('account deleted'); // No uid in logs after deletion.
  return { deleted: true };
});
