import { createHash } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import { Readable } from 'node:stream';
import { deflateSync } from 'node:zlib';

import { describe, expect, it } from 'vitest';

import { EmergencyKeywordDetector, emergencyDetector, fold } from '../src/emergency.js';
import { canonicalText, sha256Stream, sha256Text } from '../src/hash.js';
import { fillLetter, LETTER_TEMPLATES, RECIPIENTS } from '../src/letterTemplates.js';
import { polishLetter } from '../src/letters.js';
import { buildLetterPdf, buildReportPdf } from '../src/pdf.js';
import { fillPrompt, loadPromptTemplate, PROMPT_PLACEHOLDERS, type PromptValues } from '../src/prompt.js';
import { bakuDay } from '../src/rateLimit.js';
import { ruleById, ruleFiles } from '../src/rules.js';
import { LANGUAGES, readSharedJson } from '../src/shared.js';
import { strings } from '../src/i18n.js';

describe('emergency keywords (same vectors as the Flutter app)', () => {
  const { cases } = readSharedJson<{ cases: { text: string; emergency: boolean }[] }>('emergency_keyword_cases.json');
  const detector = emergencyDetector();
  for (const c of cases) {
    it(`"${c.text}" -> ${c.emergency}`, () => expect(detector.isEmergency(c.text)).toBe(c.emergency));
  }
  it('folds like the Dart implementation', () => {
    expect(fold('QAZ İYİ, Şəhər!')).toBe('qaz iyi seher');
    expect(fold('Котёл')).toBe('котел');
    expect(fold("  can't   wake ")).toBe('can t wake');
  });
  it('combos need every group', () => {
    const d = new EmergencyKeywordDetector({ phrases: {}, combos: [{ id: 'x', groups: [['headache'], ['heater']] }] });
    expect(d.isEmergency('headache')).toBe(false);
    expect(d.isEmergency('headache near the heater')).toBe(true);
  });
});

describe('evidence hashing', () => {
  it('canonical text form is fixed and documented', () => {
    expect(canonicalText({ itemId: 'abc', type: 'note', text: 'Qaz iyi' })).toBe('[1,"abc","note","Qaz iyi",null,null]');
    const expected = createHash('sha256').update('[1,"abc","note","Qaz iyi",null,null]').digest('hex');
    expect(sha256Text({ itemId: 'abc', type: 'note', text: 'Qaz iyi' })).toBe(expected);
  });
  it('any change to the text changes the hash', () => {
    const a = sha256Text({ itemId: 'abc', type: 'note', text: 'Leak since Monday' });
    const b = sha256Text({ itemId: 'abc', type: 'note', text: 'Leak since Tuesday' });
    expect(a).not.toBe(b);
  });
  it('file hash equals sha256 of the bytes', async () => {
    const bytes = Buffer.from('fake photo bytes '.repeat(1000));
    const { sha256, size } = await sha256Stream(Readable.from([bytes.subarray(0, 100), bytes.subarray(100)]));
    expect(sha256).toBe(createHash('sha256').update(bytes).digest('hex'));
    expect(size).toBe(bytes.length);
  });
});

describe('letters', () => {
  const details = {
    name: 'Leyla Məmmədova', address: 'Nəsimi r., Bakı', description: 'Kolonka 3 dəfə söndü, 12.10.2026', since: '2026-10-01',
  };
  for (const [id, template] of Object.entries(LETTER_TEMPLATES)) {
    for (const lang of LANGUAGES) {
      it(`${id} in ${lang} fills every placeholder`, () => {
        const body = fillLetter(template, lang, 'landlord', details, '18 oktyabr 2026');
        expect(body).not.toMatch(/\{\{|\}\}/);
        expect(body).toContain(details.name);
        expect(body).toContain(details.address);
        expect(body).toContain(details.since);
        expect(body).toContain(RECIPIENTS.landlord[lang]);
        expect(template.reviewed).toBe(false); // TODO(lawyer)
      });
    }
  }
  it('user text containing {{placeholders}} is not expanded', () => {
    const body = fillLetter(LETTER_TEMPLATES.leak, 'en', 'other', { ...details, description: 'see {{name}}' }, 'today');
    expect(body).toContain('see {{name}}');
  });
  it('the recipient name wins over the generic label; empty "since" removes the line', () => {
    const body = fillLetter(LETTER_TEMPLATES.leak, 'en', 'landlord', { ...details, recipientName: 'Mr. Aliyev', since: '' }, 'today');
    expect(body).toContain('To: Mr. Aliyev');
    expect(body).not.toContain('The problem started');
  });
  it('AI polish is rejected if it changes a fact, accepted if facts survive', async () => {
    const body = fillLetter(LETTER_TEMPLATES.gas_heater, 'az', 'landlord', details, 'today');
    const changed = await polishLetter(body, 'az', details, async () => body.replace('12.10.2026', '13.10.2026'));
    expect(changed).toBe(body);
    const nicer = body.replace('Salam,', 'Hörmətli ev sahibi,');
    expect(await polishLetter(body, 'az', details, async () => nicer)).toBe(nicer);
    expect(await polishLetter(body, 'az', details, async () => '')).toBe(body);
  });
});

describe('system prompt', () => {
  const values = Object.fromEntries(PROMPT_PLACEHOLDERS.map((p) => [p, `<${p}>`])) as PromptValues;
  it('the real prompt file has exactly the expected placeholders and fills cleanly', () => {
    const filled = fillPrompt(loadPromptTemplate(), values);
    expect(filled).not.toMatch(/\{\{[A-Z_]+\}\}/);
    expect(filled).toContain('<HOME_PROFILE>');
    expect(filled).toContain('[[EMERGENCY]]');
    expect(filled).not.toContain('DRAFT'); // The comment header is stripped.
  });
  it('rejects a template with an unknown or missing placeholder', () => {
    expect(() => fillPrompt('{{LANGUAGE}} {{SECRET}}', values)).toThrow(/placeholders/);
  });
  it('user-controlled values are not re-expanded', () => {
    const t = PROMPT_PLACEHOLDERS.map((p) => `{{${p}}}`).join(' ');
    const out = fillPrompt(t, { ...values, HOME_PROFILE: '{{LANGUAGE}}' });
    expect(out).toContain('{{LANGUAGE}}');
  });
});

describe('rules and translations used by the server', () => {
  it('every rule reason/step key has text in all languages', () => {
    for (const lang of LANGUAGES) {
      const t = strings(lang);
      for (const f of ruleFiles()) {
        for (const r of f.rules) {
          for (const key of [r.result.reason_key, ...r.result.steps_keys]) expect(t(key)).not.toBe(key);
        }
      }
    }
    expect(ruleById('co-bathroom-heater-no-vent-symptoms')?.result.emergency).toBe(true);
  });
  it('report/push texts exist in all languages', () => {
    for (const lang of LANGUAGES) {
      const t = strings(lang);
      for (const key of ['report.title', 'report.footer', 'push.seasonal.title', 'push.seasonal.body', 'levelRed', 'profileHeating']) {
        expect(t(key)).not.toBe(key);
      }
    }
  });
});

describe('rate limit day', () => {
  it('uses the Baku calendar day (UTC+4)', () => {
    expect(bakuDay(new Date('2026-10-18T19:59:00Z'))).toBe('2026-10-18');
    expect(bakuDay(new Date('2026-10-18T20:00:00Z'))).toBe('2026-10-19');
  });
});

/** Tiny valid PNG (solid colour) so the report test embeds a real image. */
function solidPng(w: number, h: number, rgb: [number, number, number]): Buffer {
  const crcTable = Array.from({ length: 256 }, (_, n) => {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    return c >>> 0;
  });
  const crc = (buf: Buffer) => {
    let c = 0xffffffff;
    for (const b of buf) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
  };
  const chunk = (type: string, data: Buffer) => {
    const len = Buffer.alloc(4);
    len.writeUInt32BE(data.length);
    const td = Buffer.concat([Buffer.from(type), data]);
    const c = Buffer.alloc(4);
    c.writeUInt32BE(crc(td));
    return Buffer.concat([len, td, c]);
  };
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr.set([8, 2, 0, 0, 0], 8);
  const row = Buffer.concat([Buffer.from([0]), Buffer.from(Array.from({ length: w }, () => rgb).flat())]);
  const raw = Buffer.concat(Array.from({ length: h }, () => row));
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0)),
  ]);
}

describe('PDF', () => {
  mkdirSync('test-output', { recursive: true });
  const base = {
    generatedAt: new Date('2026-10-18T09:30:00Z'),
    from: new Date('2026-09-01T00:00:00Z'),
    to: new Date('2026-10-18T00:00:00Z'),
    profile: { role: 'renter', district: 'nasimi', buildingAgeBand: '1960_1990', heatingType: 'individual_gas_heater', heaterLocation: 'bathroom', hasCoAlarm: 'no', hasWrittenContract: false },
    checks: [{
      hazard: 'gas_co', resultLevel: 'red', matchedRuleIds: ['co-bathroom-heater-no-vent-symptoms'],
      reasonKeys: ['rule.co_bathroom_no_vent.reason', 'rule.co_no_alarm.reason'], rulesVersion: 1, createdAt: new Date('2026-10-10T08:00:00Z'),
    }],
    evidence: [
      { id: 'e1', type: 'photo', text: 'Vanna otağında kolonka / Колонка в ванной', sha256: 'a'.repeat(64), serverTime: new Date('2026-10-10T08:01:00Z'), photo: solidPng(64, 48, [90, 140, 160]) },
      { id: 'e2', type: 'note', text: 'Ev sahibinə zəng etdim, cavab vermədi. Şüşə, ğ, ı, ö, ü, ç, ş, ə.', sha256: 'b'.repeat(64), serverTime: new Date('2026-10-11T12:00:00Z') },
      { id: 'e3', type: 'symptom', text: 'Головная боль по утрам, ёлка, щётка.', sha256: null, serverTime: null },
    ],
  };

  for (const lang of LANGUAGES) {
    it(`report in ${lang} renders with the Noto font embedded`, async () => {
      const pdf = await buildReportPdf({ ...base, lang });
      writeFileSync(`test-output/report_${lang}.pdf`, pdf);
      expect(pdf.subarray(0, 5).toString()).toBe('%PDF-');
      expect(pdf.toString('latin1')).toMatch(/NotoSans/);
      expect(pdf.length).toBeGreaterThan(10_000);
    });
  }

  it('letter PDF in Azerbaijani', async () => {
    const body = fillLetter(LETTER_TEMPLATES.damp_mold, 'az', 'building_manager',
      { name: 'Əli Həsənov', address: 'Yasamal r., Bakı', description: 'Yataq otağında qara kif, pəncərələr yaş olur.', since: 'sentyabr' }, '18 oktyabr 2026');
    const pdf = await buildLetterPdf('az', body);
    writeFileSync('test-output/letter_az.pdf', pdf);
    expect(pdf.toString('latin1')).toMatch(/NotoSans/);
  });
});

describe('App Check', () => {
  it('is enforced unless running inside the local Functions emulator', async () => {
    const { ENFORCE_APP_CHECK, IN_EMULATOR, APP_CHECK_REQUIRED } = await import('../src/config.js');
    expect(IN_EMULATOR).toBe(process.env.FUNCTIONS_EMULATOR === 'true');
    if (process.env.FUNCTIONS_EMULATOR !== 'true') {
      // A deploy-time param that defaults to ON.
      expect(ENFORCE_APP_CHECK).toBe(APP_CHECK_REQUIRED);
      expect((APP_CHECK_REQUIRED as unknown as { options: { default: boolean } }).options.default).toBe(true);
    }
  });
});

describe('assistant answer formatting', () => {
  it('strips Markdown so the app shows clean text', async () => {
    const { toPlainText } = await import('../src/ask.js');
    expect(toPlainText('1.  **Ventilate.** Open windows\n* dry clothes outside\n## Tip\n`code`'))
      .toBe('1.  Ventilate. Open windows\n• dry clothes outside\nTip\ncode');
  });
});

describe('off-topic requests', () => {
  it('replace the model output with a fixed refusal in the user language', async () => {
    const { finalizeAnswer } = await import('../src/ask.js');
    const en = finalizeAnswer('[[OFF_TOPIC]]', 'en');
    expect(en.offTopic).toBe(true);
    expect(en.answer).toMatch(/only help with home safety/);
    // Even if the model leaks text around the marker, none of it is shown.
    const leaky = finalizeAnswer('[[OFF_TOPIC]]\ndef sort(xs): return sorted(xs)', 'az');
    expect(leaky.answer).not.toContain('def ');
    expect(leaky.answer).toMatch(/yalnız evdə təhlükəsizlik/);
    expect(finalizeAnswer('', 'ru').answer).toMatch(/только с безопасностью дома/);
    const normal = finalizeAnswer('[[EMERGENCY]]\n1. **Leave** now', 'en');
    expect(normal).toEqual({ answer: '1. Leave now', mentionsEmergency: true, offTopic: false });
  });
});

describe('temporary file cleanup', () => {
  it('deletes generated files only after one day', async () => {
    const { isExpired, TEMP_PREFIXES } = await import('../src/cleanup.js');
    const now = Date.parse('2026-10-22T12:00:00Z');
    expect(isExpired('2026-10-21T11:59:00Z', now)).toBe(true);
    expect(isExpired('2026-10-22T09:00:00Z', now)).toBe(false);
    expect(isExpired(undefined, now)).toBe(false);
    expect(TEMP_PREFIXES).not.toContain('users/'); // Evidence photos are never cleaned up.
  });
});
