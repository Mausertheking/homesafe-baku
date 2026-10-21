import { readSharedJson } from './shared.js';

/**
 * Emergency keyword detection. Must behave exactly like
 * app/lib/features/emergency/emergency_keywords.dart: both read
 * shared/emergency_keywords.json and both pass
 * shared/emergency_keyword_cases.json.
 */
interface KeywordFile {
  phrases: Record<string, string[]>;
  combos: { id: string; groups: string[][] }[];
}

const LETTERS: Record<string, string> = { 'ə': 'e', 'ı': 'i', 'ğ': 'g', 'ö': 'o', 'ü': 'u', 'ç': 'c', 'ş': 's', 'ё': 'е' };

/** Lowercase, Azerbaijani letters to ASCII, ё→е, strip combining marks (the
 * dot left over from lowercasing "İ"), non-letters to single spaces. */
export function fold(input: string): string {
  let out = '';
  for (const ch of input.toLowerCase()) out += LETTERS[ch] ?? ch;
  return out
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
}

export class EmergencyKeywordDetector {
  private readonly phrases: string[];
  private readonly combos: string[][][];

  constructor(file: KeywordFile) {
    this.phrases = [...new Set(Object.values(file.phrases).flat().map(fold))].filter(Boolean);
    this.combos = file.combos.map((c) => c.groups.map((g) => g.map(fold)));
  }

  isEmergency(message: string): boolean {
    const text = ' ' + fold(message);
    if (text.trim() === '') return false;
    const has = (phrase: string) => text.includes(' ' + phrase);
    if (this.phrases.some(has)) return true;
    return this.combos.some((groups) => groups.every((g) => g.some(has)));
  }
}

let cached: EmergencyKeywordDetector | undefined;
export function emergencyDetector(): EmergencyKeywordDetector {
  cached ??= new EmergencyKeywordDetector(readSharedJson<KeywordFile>('emergency_keywords.json'));
  return cached;
}
