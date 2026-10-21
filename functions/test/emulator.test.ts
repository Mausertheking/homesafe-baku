import { afterAll, beforeEach, describe, expect, it, vi } from 'vitest';

/**
 * askHomeSafe and account deletion against the Firestore emulator, with a fake
 * Gemini. Runs only inside `firebase emulators:exec` (npm run test:emulator).
 */
const onEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
process.env.GCLOUD_PROJECT ??= 'demo-homesafe';

describe.skipIf(!onEmulator)('askHomeSafe core (Firestore emulator)', async () => {
  const { db } = await import('../src/admin.js');
  const { askHomeSafeCore } = await import('../src/ask.js');
  const { deleteUserData } = await import('../src/account.js');
  const { CHAT_DAILY_LIMIT } = await import('../src/config.js');
  const firestore = db();
  const UID = 'dave';

  const input = (message: string) => ({ uid: UID, homeId: 'h1', message, language: 'az' as const, photo: null });

  beforeEach(async () => {
    await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-homesafe/databases/(default)/documents`, { method: 'DELETE' });
    await firestore.doc(`users/${UID}`).set({ language: 'az', role: 'renter' });
    await firestore.doc(`users/${UID}/homes/h1`).set({ district: 'nasimi', heatingType: 'individual_gas_heater', heaterLocation: 'bathroom', hasCoAlarm: 'no' });
    await firestore.doc(`users/${UID}/homes/h1/checks/c1`).set({
      hazard: 'gas_co', resultLevel: 'red', matchedRuleIds: ['co-bathroom-heater-no-vent'], rulesVersion: 1, createdAt: new Date(),
    });
  });
  afterAll(async () => {
    await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-homesafe/databases/(default)/documents`, { method: 'DELETE' });
  });

  it('emergency keywords never reach Gemini', async () => {
    const gemini = vi.fn(async () => 'should not be called');
    for (const msg of ['Vannada qaz iyi gəlir', 'Пахнет газом', 'my CO alarm is beeping']) {
      const res = await askHomeSafeCore(firestore, input(msg), gemini);
      expect(res).toEqual({ emergency: true, answer: null, mentionsEmergency: true });
    }
    expect(gemini).not.toHaveBeenCalled();
  });

  it('answers normal questions with the home context in the system prompt', async () => {
    const gemini = vi.fn(async (req: { systemInstruction: string }) => {
      expect(req.systemInstruction).toContain('individual_gas_heater');
      expect(req.systemInstruction).toContain('co-bathroom-heater-no-vent');
      expect(req.systemInstruction).toContain('Azerbaijani');
      expect(req.systemInstruction).not.toMatch(/\{\{[A-Z_]+\}\}/);
      return '[[EMERGENCY]]\nÇölə çıxın.';
    });
    const res = await askHomeSafeCore(firestore, input('Kolonkanı necə yoxlayım?'), gemini);
    expect(res).toEqual({ emergency: false, answer: 'Çölə çıxın.', mentionsEmergency: true });
  });

  it(`allows ${CHAT_DAILY_LIMIT} messages a day, then refuses`, async () => {
    const gemini = vi.fn(async () => 'ok');
    for (let i = 0; i < CHAT_DAILY_LIMIT; i++) await askHomeSafeCore(firestore, input(`sual ${i}`), gemini);
    await expect(askHomeSafeCore(firestore, input('one more'), gemini)).rejects.toMatchObject({ code: 'resource-exhausted' });
    expect(gemini).toHaveBeenCalledTimes(CHAT_DAILY_LIMIT);
  });

  it('abuse log stores metadata only, never the message or answer', async () => {
    await askHomeSafeCore(firestore, input('Divarda kif var, nə edim? Ünvanım Nizami küç. 5'), async () => 'Cavab mətni');
    const logs = await firestore.collection('abuseLog').where('uid', '==', UID).get();
    expect(logs.size).toBeGreaterThan(0);
    const all = JSON.stringify(logs.docs.map((d) => d.data()));
    expect(all).not.toContain('Divarda');
    expect(all).not.toContain('Nizami');
    expect(all).not.toContain('Cavab');
  });

  it('deleteUserData removes the user tree, usage and logs', async () => {
    await askHomeSafeCore(firestore, input('salam'), async () => 'ok');
    await deleteUserData(firestore, UID);
    expect((await firestore.doc(`users/${UID}`).get()).exists).toBe(false);
    expect((await firestore.doc(`users/${UID}/homes/h1/checks/c1`).get()).exists).toBe(false);
    expect((await firestore.collection('usage').where('uid', '==', UID).get()).size).toBe(0);
    expect((await firestore.collection('abuseLog').where('uid', '==', UID).get()).size).toBe(0);
  });
});
