import type { Language } from './shared.js';

/**
 * Default letter templates. Seeded into Firestore letterTemplates/{problemId}
 * (scripts/seed.ts); generateLetter reads Firestore first and falls back to
 * these. They make NO legal claims and cite no laws on purpose.
 * TODO(lawyer): review wording in all three languages; add law references
 * only after review.
 *
 * Placeholders: {{recipient}} {{name}} {{address}} {{date}} {{description}}
 * {{sinceLine}} {{subject}} {{problem}} {{request}}
 */
export interface LetterTemplate {
  subject: Record<Language, string>;
  problem: Record<Language, string>;
  request: Record<Language, string>;
  reviewed: boolean;
}

export const LETTER_BODY: Record<Language, string> = {
  en: `To: {{recipient}}
From: {{name}}
Address: {{address}}
Date: {{date}}

Subject: {{subject}}

Hello,

I am writing about a problem at the address above. {{problem}}

What I have noticed: {{description}}
{{sinceLine}}

{{request}}

I am keeping a dated record of this problem, with photos and notes.

Please reply in writing and let me know when this will be done.

Kind regards,
{{name}}`,
  az: `Kimə: {{recipient}}
Kimdən: {{name}}
Ünvan: {{address}}
Tarix: {{date}}

Mövzu: {{subject}}

Salam,

Yuxarıdakı ünvandakı problemlə bağlı müraciət edirəm. {{problem}}

Müşahidə etdiklərim: {{description}}
{{sinceLine}}

{{request}}

Bu problemi şəkillər və qeydlərlə, tarixləri ilə birlikdə qeyd edirəm.

Xahiş edirəm, yazılı cavab verəsiniz və bunun nə vaxt ediləcəyini bildirəsiniz.

Hörmətlə,
{{name}}`,
  ru: `Кому: {{recipient}}
От: {{name}}
Адрес: {{address}}
Дата: {{date}}

Тема: {{subject}}

Здравствуйте,

Пишу по поводу проблемы по указанному адресу. {{problem}}

Что я заметил(а): {{description}}
{{sinceLine}}

{{request}}

Я веду записи об этой проблеме с датами, фотографиями и заметками.

Прошу ответить письменно и сообщить, когда это будет сделано.

С уважением,
{{name}}`,
};

export const SINCE_LINE: Record<Language, string> = {
  en: 'The problem started: {{since}}',
  az: 'Problem başlayıb: {{since}}',
  ru: 'Проблема началась: {{since}}',
};

export const RECIPIENTS: Record<string, Record<Language, string>> = {
  landlord: { en: 'Landlord', az: 'Ev sahibi', ru: 'Арендодатель' },
  building_manager: { en: 'Building manager', az: 'Bina idarəsi', ru: 'Управление домом' },
  azerigaz: { en: 'Azerigaz', az: 'Azəriqaz', ru: 'Азеригаз' },
  other: { en: 'To whom it may concern', az: 'Aidiyyəti üzrə', ru: 'По месту требования' },
};

export const LETTER_TEMPLATES: Record<string, LetterTemplate> = {
  gas_heater: {
    reviewed: false,
    subject: { en: 'Request to inspect and repair a gas heater', az: 'Qaz qızdırıcısının yoxlanılması və təmiri xahişi', ru: 'Просьба проверить и отремонтировать газовый обогреватель' },
    problem: { en: 'There is a problem with the gas heater.', az: 'Qaz qızdırıcısında problem var.', ru: 'Есть проблема с газовым обогревателем.' },
    request: {
      en: 'Please arrange for a qualified gas professional to inspect and repair the gas heater as soon as possible.',
      az: 'Xahiş edirəm, qaz qızdırıcısının ixtisaslı qaz ustası tərəfindən mümkün qədər tez yoxlanılmasını və təmirini təşkil edəsiniz.',
      ru: 'Прошу как можно скорее организовать проверку и ремонт газового обогревателя квалифицированным газовым мастером.',
    },
  },
  co_alarm_missing: {
    reviewed: false,
    subject: { en: 'Request for a carbon monoxide alarm', az: 'Dəm qazı siqnalizatoru xahişi', ru: 'Просьба установить датчик угарного газа' },
    problem: { en: 'The home has gas appliances but no working carbon monoxide (CO) alarm.', az: 'Evdə qaz cihazları var, amma işləyən dəm qazı (CO) siqnalizatoru yoxdur.', ru: 'В жилье есть газовые приборы, но нет рабочего датчика угарного газа (CO).' },
    request: {
      en: 'Please install a working carbon monoxide alarm near the gas appliances and the bedrooms.',
      az: 'Xahiş edirəm, qaz cihazlarının və yataq otaqlarının yaxınlığında işləyən dəm qazı siqnalizatoru quraşdırasınız.',
      ru: 'Прошу установить рабочий датчик угарного газа рядом с газовыми приборами и спальнями.',
    },
  },
  damp_mold: {
    reviewed: false,
    subject: { en: 'Request to fix damp and mold', az: 'Rütubətin və kifin aradan qaldırılması xahişi', ru: 'Просьба устранить сырость и плесень' },
    problem: { en: 'There is damp and mold in the home.', az: 'Evdə rütubət və kif var.', ru: 'В жилье сырость и плесень.' },
    request: {
      en: 'Please inspect the home, find the cause of the damp and mold, fix it, and repair the damage.',
      az: 'Xahiş edirəm, evi yoxlayasınız, rütubətin və kifin səbəbini tapıb aradan qaldırasınız və zədələri təmir edəsiniz.',
      ru: 'Прошу осмотреть жильё, найти и устранить причину сырости и плесени и отремонтировать повреждения.',
    },
  },
  leak: {
    reviewed: false,
    subject: { en: 'Request to repair a leak', az: 'Sızmanın təmiri xahişi', ru: 'Просьба устранить протечку' },
    problem: { en: 'There is a water leak.', az: 'Su sızması var.', ru: 'Есть протечка воды.' },
    request: {
      en: 'Please find and repair the leak as soon as possible, and repair any damage it has caused.',
      az: 'Xahiş edirəm, sızmanı mümkün qədər tez tapıb təmir edəsiniz və onun vurduğu zədələri aradan qaldırasınız.',
      ru: 'Прошу как можно скорее найти и устранить протечку и отремонтировать причинённые ею повреждения.',
    },
  },
  other: {
    reviewed: false,
    subject: { en: 'Request for a repair', az: 'Təmir xahişi', ru: 'Просьба о ремонте' },
    problem: { en: 'There is a problem that needs attention.', az: 'Diqqət tələb edən problem var.', ru: 'Есть проблема, требующая внимания.' },
    request: {
      en: 'Please inspect and repair this problem as soon as possible.',
      az: 'Xahiş edirəm, bu problemi mümkün qədər tez yoxlayıb təmir edəsiniz.',
      ru: 'Прошу как можно скорее осмотреть и устранить эту проблему.',
    },
  },
};

export interface LetterDetails {
  name: string;
  address: string;
  recipientName?: string;
  description: string;
  since?: string;
}

/** Fills a template. Pure, so it is unit-tested. User text is inserted as-is. */
export function fillLetter(
  template: LetterTemplate,
  lang: Language,
  recipient: string,
  details: LetterDetails,
  date: string,
): string {
  const values: Record<string, string> = {
    recipient: details.recipientName?.trim() || RECIPIENTS[recipient]?.[lang] || RECIPIENTS.other[lang],
    name: details.name.trim(),
    address: details.address.trim(),
    date,
    subject: template.subject[lang],
    problem: template.problem[lang],
    request: template.request[lang],
    description: details.description.trim(),
    sinceLine: details.since?.trim() ? SINCE_LINE[lang].replace('{{since}}', details.since.trim()) : '',
  };
  // Single pass, so user text containing "{{...}}" is never re-expanded.
  return LETTER_BODY[lang]
    .replace(/\{\{(\w+)\}\}/g, (_, key: string) => values[key] ?? '')
    .replace(/\n{3,}/g, '\n\n');
}
