import { readFileSync } from 'node:fs';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection, deleteDoc, doc, getDoc, getDocs, serverTimestamp, setDoc, Timestamp, updateDoc,
} from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

/**
 * Proves the acceptance criterion "a user cannot read or change another
 * user's data", plus the evidence immutability rules, against the real
 * emulators. Run with: npm test (from security-tests/).
 */
let env: RulesTestEnvironment;
const ALICE = 'alice';
const BOB = 'bob';
const HOME = 'home1';
const base = `users/${ALICE}/homes/${HOME}`;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-homesafe',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
    storage: { rules: readFileSync('../storage.rules', 'utf8'), host: '127.0.0.1', port: 9199 },
  });
});
afterAll(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  // Alice's existing data, written as the server would.
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `users/${ALICE}`), { language: 'az', createdAt: Timestamp.now() });
    await setDoc(doc(db, base), { district: 'nasimi', heatingType: 'gas_boiler' });
    await setDoc(doc(db, `${base}/evidence/old`), { type: 'note', text: 'kif', deleted: false, createdAt: Timestamp.now(), sha256: 'x'.repeat(64) });
    await setDoc(doc(db, `${base}/checks/c1`), { hazard: 'gas_co', answers: {}, resultLevel: 'green', matchedRuleIds: [], rulesVersion: 1, createdAt: Timestamp.now() });
    await setDoc(doc(db, `${base}/letters/l1`), { body: 'Salam', createdAt: Timestamp.now() });
    await setDoc(doc(db, 'rules/r1'), { check: 'gas_co', rule: {} });
    await setDoc(doc(db, 'legalTopics/repairs'), { title: { az: 'Təmir' } });
    await setDoc(doc(db, 'config/app'), { rulesVersion: 1 });
    await setDoc(doc(db, `usage/${ALICE}_2026-10-18`), { uid: ALICE, count: 3 });
    await setDoc(doc(db, 'abuseLog/a1'), { uid: ALICE });
    await uploadBytes(ref(ctx.storage(), `${base}/evidence/old/photo.jpg`), new Uint8Array([1, 2, 3]), { contentType: 'image/jpeg' });
  });
});

const alice = () => env.authenticatedContext(ALICE).firestore();
const bob = () => env.authenticatedContext(BOB).firestore();
const anon = () => env.unauthenticatedContext().firestore();
const note = (extra: Record<string, unknown> = {}) => ({ type: 'note', text: 'Qaz iyi', deleted: false, createdAt: serverTimestamp(), ...extra });

describe('rules: isolation between users', () => {
  it('owner can read their own documents', async () => {
    await assertSucceeds(getDoc(doc(alice(), `users/${ALICE}`)));
    await assertSucceeds(getDoc(doc(alice(), base)));
    await assertSucceeds(getDocs(collection(alice(), `${base}/evidence`)));
    await assertSucceeds(getDoc(doc(alice(), `${base}/letters/l1`)));
  });

  for (const path of [`users/${ALICE}`, base, `${base}/evidence/old`, `${base}/checks/c1`, `${base}/letters/l1`]) {
    it(`another user cannot read ${path}`, async () => {
      await assertFails(getDoc(doc(bob(), path)));
    });
    it(`signed-out users cannot read ${path}`, async () => {
      await assertFails(getDoc(doc(anon(), path)));
    });
  }

  it('another user cannot list or query Alice\'s evidence', async () => {
    await assertFails(getDocs(collection(bob(), `${base}/evidence`)));
  });

  it('another user cannot write anything of Alice\'s', async () => {
    await assertFails(setDoc(doc(bob(), `users/${ALICE}`), { language: 'en', createdAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(bob(), `users/${ALICE}`), { language: 'en' }));
    await assertFails(setDoc(doc(bob(), base), { district: 'yasamal' }));
    await assertFails(setDoc(doc(bob(), `${base}/evidence/new`), note()));
    await assertFails(updateDoc(doc(bob(), `${base}/evidence/old`), { deleted: true, deletedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(bob(), `${base}/checks/c2`), {
      hazard: 'gas_co', answers: {}, resultLevel: 'red', matchedRuleIds: [], rulesVersion: 1, createdAt: serverTimestamp(),
    }));
  });
});

describe('rules: users and homes', () => {
  it('a new user can create their own profile with valid fields only', async () => {
    const bobDb = bob();
    await assertFails(setDoc(doc(bobDb, `users/${BOB}`), { language: 'xx', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(bobDb, `users/${BOB}`), { language: 'az', createdAt: serverTimestamp(), admin: true }));
    await assertSucceeds(setDoc(doc(bobDb, `users/${BOB}`), { language: 'az', createdAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(bobDb, `users/${BOB}`), { language: 'ru', role: 'renter' }));
    await assertFails(updateDoc(doc(bobDb, `users/${BOB}`), { createdAt: serverTimestamp() }));
    await assertFails(deleteDoc(doc(bobDb, `users/${BOB}`)));
  });

  it('home profile accepts known values and rejects unknown fields', async () => {
    await assertSucceeds(setDoc(doc(alice(), base), {
      district: 'yasamal', buildingAgeBand: '1960_1990', heatingType: 'individual_gas_heater',
      heaterLocation: 'bathroom', hasCoAlarm: 'no', hasWrittenContract: null,
    }));
    await assertFails(setDoc(doc(alice(), base), { heatingType: 'nuclear' }));
    await assertFails(setDoc(doc(alice(), base), { district: 'nasimi', phone: '+994501234567' }));
  });
});

describe('rules: evidence is append-only', () => {
  it('owner can add a note with a server timestamp', async () => {
    await assertSucceeds(setDoc(doc(alice(), `${base}/evidence/n1`), note()));
  });

  it('client cannot set sha256 or serverTime', async () => {
    await assertFails(setDoc(doc(alice(), `${base}/evidence/n2`), note({ sha256: 'f'.repeat(64) })));
    await assertFails(setDoc(doc(alice(), `${base}/evidence/n3`), note({ serverTime: serverTimestamp() })));
  });

  it('client cannot back-date evidence', async () => {
    await assertFails(setDoc(doc(alice(), `${base}/evidence/n4`), note({ createdAt: Timestamp.fromDate(new Date('2020-01-01')) })));
  });

  it('client cannot create letter evidence or already-deleted items', async () => {
    await assertFails(setDoc(doc(alice(), `${base}/evidence/n5`), note({ type: 'letter' })));
    await assertFails(setDoc(doc(alice(), `${base}/evidence/n6`), note({ deleted: true })));
  });

  it('photo evidence must point at its own private path', async () => {
    const p = (id: string, storagePath: string) => ({ type: 'photo', text: '', storagePath, deleted: false, createdAt: serverTimestamp() });
    await assertSucceeds(setDoc(doc(alice(), `${base}/evidence/p1`), p('p1', `${base}/evidence/p1/photo.jpg`)));
    await assertFails(setDoc(doc(alice(), `${base}/evidence/p2`), p('p2', `users/${BOB}/homes/h/evidence/x/photo.jpg`)));
    await assertFails(setDoc(doc(alice(), `${base}/evidence/p3`), p('p3', `${base}/evidence/OTHER/photo.jpg`)));
    await assertFails(setDoc(doc(alice(), `${base}/evidence/p4`), { type: 'photo', text: '', deleted: false, createdAt: serverTimestamp() }));
  });

  it('evidence cannot be edited after creation', async () => {
    await assertFails(updateDoc(doc(alice(), `${base}/evidence/old`), { text: 'changed' }));
    await assertFails(updateDoc(doc(alice(), `${base}/evidence/old`), { sha256: '0'.repeat(64) }));
    await assertFails(updateDoc(doc(alice(), `${base}/evidence/old`), { createdAt: serverTimestamp() }));
  });

  it('evidence can only be marked deleted (never removed, never un-deleted)', async () => {
    await assertFails(deleteDoc(doc(alice(), `${base}/evidence/old`)));
    await assertFails(updateDoc(doc(alice(), `${base}/evidence/old`), { deleted: true, deletedAt: serverTimestamp(), text: 'x' }));
    await assertSucceeds(updateDoc(doc(alice(), `${base}/evidence/old`), { deleted: true, deletedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(alice(), `${base}/evidence/old`), { deleted: false }));
  });
});

describe('rules: checks and letters', () => {
  const check = { hazard: 'damp_mold', answers: { visible_leak: true }, resultLevel: 'amber', matchedRuleIds: ['damp-visible-leak'], rulesVersion: 1 };
  it('owner can save a check; it cannot be changed or removed', async () => {
    await assertSucceeds(setDoc(doc(alice(), `${base}/checks/c9`), { ...check, createdAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(alice(), `${base}/checks/c1`), { resultLevel: 'green' }));
    await assertFails(deleteDoc(doc(alice(), `${base}/checks/c1`)));
    await assertFails(setDoc(doc(alice(), `${base}/checks/c10`), { ...check, resultLevel: 'purple', createdAt: serverTimestamp() }));
  });
  it('letters are written by the server only', async () => {
    await assertFails(setDoc(doc(alice(), `${base}/letters/l2`), { body: 'x', createdAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(alice(), `${base}/letters/l1`), { body: 'changed' }));
  });
});

describe('rules: shared and server-only collections', () => {
  for (const path of ['rules/r1', 'legalTopics/repairs', 'config/app']) {
    it(`${path} is readable but not writable`, async () => {
      await assertSucceeds(getDoc(doc(anon(), path)));
      await assertFails(setDoc(doc(alice(), path), { hacked: true }));
      await assertFails(deleteDoc(doc(alice(), path)));
    });
  }
  for (const path of [`usage/${ALICE}_2026-10-18`, 'abuseLog/a1']) {
    it(`${path} is server-only (even for its owner)`, async () => {
      await assertFails(getDoc(doc(alice(), path)));
      await assertFails(setDoc(doc(alice(), path), { count: 0, uid: ALICE }));
    });
  }
});

describe('rules: storage', () => {
  const st = (uid: string) => env.authenticatedContext(uid).storage();
  const jpeg = { contentType: 'image/jpeg' };
  it('owner can upload a photo once to their own evidence path', async () => {
    await assertSucceeds(uploadBytes(ref(st(ALICE), `${base}/evidence/p1/photo.jpg`), new Uint8Array([9]), jpeg));
  });
  it('photos cannot be replaced or deleted by the client', async () => {
    await assertFails(uploadBytes(ref(st(ALICE), `${base}/evidence/old/photo.jpg`), new Uint8Array([7]), jpeg));
    await assertFails(deleteObject(ref(st(ALICE), `${base}/evidence/old/photo.jpg`)));
  });
  it('owner can read; other users and signed-out users cannot', async () => {
    await assertSucceeds(getBytes(ref(st(ALICE), `${base}/evidence/old/photo.jpg`)));
    await assertFails(getBytes(ref(st(BOB), `${base}/evidence/old/photo.jpg`)));
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), `${base}/evidence/old/photo.jpg`)));
  });
  it('another user cannot upload into Alice\'s folder', async () => {
    await assertFails(uploadBytes(ref(st(BOB), `${base}/evidence/p2/photo.jpg`), new Uint8Array([1]), jpeg));
  });
  it('only images, only photo.jpg, under 15 MB', async () => {
    await assertFails(uploadBytes(ref(st(ALICE), `${base}/evidence/p3/photo.jpg`), new Uint8Array([1]), { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(st(ALICE), `${base}/evidence/p4/evil.html`), new Uint8Array([1]), jpeg));
    await assertFails(uploadBytes(ref(st(ALICE), `${base}/evidence/p5/photo.jpg`), new Uint8Array(15 * 1024 * 1024 + 1), jpeg));
  });
  it('reports, letters and exports are never directly readable', async () => {
    for (const p of [`reports/${ALICE}/r.pdf`, `letters/${ALICE}/l.pdf`, `exports/${ALICE}/e.zip`]) {
      await assertFails(getBytes(ref(st(ALICE), p)));
      await assertFails(uploadBytes(ref(st(ALICE), p), new Uint8Array([1])));
    }
  });
});
