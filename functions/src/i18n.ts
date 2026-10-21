import { type Language, readSharedJson } from './shared.js';

/**
 * Server-side texts come from the SAME ARB files as the app (synced into
 * functions/shared/l10n), so PDFs and push messages always match the app.
 */
type Strings = Record<string, string>;

function load(file: string): Strings {
  const raw = readSharedJson<Record<string, unknown>>('l10n', file);
  return Object.fromEntries(Object.entries(raw).filter(([k, v]) => !k.startsWith('@') && typeof v === 'string')) as Strings;
}

const cache = new Map<Language, Strings>();

export function strings(lang: Language): (key: string, params?: Record<string, string | number>) => string {
  if (!cache.has(lang)) cache.set(lang, { ...load(`app_${lang}.arb`), ...load(`content_${lang}.arb`) });
  if (!cache.has('en')) cache.set('en', { ...load('app_en.arb'), ...load('content_en.arb') });
  const s = cache.get(lang)!;
  const en = cache.get('en')!;
  return (key, params = {}) => {
    let value = s[key] ?? en[key] ?? key;
    for (const [p, v] of Object.entries(params)) value = value.replaceAll(`{${p}}`, String(v));
    return value;
  };
}

/** Profile value ids → app ARB keys, used to print the home profile. */
export const PROFILE_VALUE_KEYS: Record<string, Record<string, string>> = {
  role: { renter: 'roleRenter', owner: 'roleOwner' },
  buildingAgeBand: {
    before_1960: 'ageBefore1960', '1960_1990': 'age1960to1990', '1991_2010': 'age1991to2010',
    after_2010: 'ageAfter2010', not_sure: 'notSure',
  },
  heatingType: {
    individual_gas_heater: 'heatingIndividualGas', gas_boiler: 'heatingGasBoiler', central_heating: 'heatingCentral',
    electric: 'heatingElectric', other: 'heatingOther',
  },
  heaterLocation: { bathroom: 'waterHeaterBathroom', kitchen: 'waterHeaterKitchen', other: 'waterHeaterOther', none: 'waterHeaterNone' },
  hasCoAlarm: { yes: 'yes', no: 'no', not_sure: 'notSure' },
};
