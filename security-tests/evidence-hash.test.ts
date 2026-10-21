import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';

import { initializeTestEnvironment, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, updateDoc, type Firestore } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

/**
 * End-to-end: a real client write → the onEvidenceCreated function (running
 * in the Functions emulator) → sha256 + serverTime on the document.
 * Skipped when the Functions emulator is not running (npm run test:rules).
 */
const functionsRunning = !!process.env.FUNCTIONS_EMULATOR_HOST || !!process.env.FIREBASE_EMULATOR_HUB && await fetch('http://127.0.0.1:5001').then(() => true, () => false);

let env: RulesTestEnvironment;
const UID = 'carol';
const base = `users/${UID}/homes/h1`;

async function waitForHash(db: Firestore, path: string): Promise<Record<string, unknown>> {
  for (let i = 0; i < 60; i++) {
    const snap = await getDoc(doc(db, path));
    const data = snap.data();
    if (data?.sha256 || data?.hashError) return data;
    await new Promise((r) => setTimeout(r, 500));
  }
  throw new Error(`no hash on ${path} after 30 s`);
}

describe.skipIf(!functionsRunning)('onEvidenceCreated (Functions emulator)', () => {
  beforeAll(async () => {
    env = await initializeTestEnvironment({
      projectId: 'demo-homesafe',
      firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
      storage: { rules: readFileSync('../storage.rules', 'utf8'), host: '127.0.0.1', port: 9199 },
    });
  });
  afterAll(async () => env?.cleanup());

  it('hashes a note with the documented canonical form and stores the server time', async () => {
    const ctx = env.authenticatedContext(UID);
    const db = ctx.firestore();
    const before = Date.now();
    await setDoc(doc(db, `${base}/evidence/note1`), { type: 'note', text: 'Qaz iyi gəlir — запах газа', deleted: false, createdAt: serverTimestamp() });
    const data = await waitForHash(db, `${base}/evidence/note1`);
    const expected = createHash('sha256')
      .update(JSON.stringify([1, 'note1', 'note', 'Qaz iyi gəlir — запах газа', null, null]))
      .digest('hex');
    expect(data.sha256).toBe(expected);
    const serverTime = (data.serverTime as { toMillis(): number }).toMillis();
    expect(serverTime).toBeGreaterThanOrEqual(before - 5000);
    expect(data.hashVersion).toBe(1);

    // And it still cannot be edited afterwards.
    await expect(updateDoc(doc(db, `${base}/evidence/note1`), { text: 'changed' })).rejects.toThrow();
  });

  it('hashes the uploaded photo bytes', async () => {
    const ctx = env.authenticatedContext(UID);
    const bytes = new Uint8Array(Array.from({ length: 5000 }, (_, i) => i % 251));
    const path = `${base}/evidence/photo1/photo.jpg`;
    // Same default bucket the Admin SDK uses inside the Functions emulator.
    await uploadBytes(ref(ctx.storage('gs://demo-homesafe.appspot.com'), path), bytes, { contentType: 'image/jpeg' });
    await setDoc(doc(ctx.firestore(), `${base}/evidence/photo1`), {
      type: 'photo', text: '', storagePath: path, deleted: false, createdAt: serverTimestamp(),
    });
    const data = await waitForHash(ctx.firestore(), `${base}/evidence/photo1`);
    expect(data.sha256).toBe(createHash('sha256').update(bytes).digest('hex'));
    expect(data.fileSize).toBe(bytes.length);
  });
});
