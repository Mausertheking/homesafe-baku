import { readShared } from './shared.js';

export const PROMPT_PLACEHOLDERS = [
  'CURRENT_DATE', 'LANGUAGE', 'EMERGENCY_NUMBERS', 'HOME_PROFILE', 'LATEST_CHECK', 'RELEVANT_RULES', 'LEGAL_TOPICS',
] as const;
export type PromptValues = Record<(typeof PROMPT_PLACEHOLDERS)[number], string>;

const MARKER = '=== PROMPT ===';

/** The prompt text after the marker line of homesafe-gemini-system-prompt.md. */
export function loadPromptTemplate(source = readShared('homesafe-gemini-system-prompt.md')): string {
  const i = source.indexOf(MARKER);
  return (i >= 0 ? source.slice(i + MARKER.length) : source).trim();
}

/**
 * Fills {{PLACEHOLDERS}}. Throws if the template has a placeholder we do not
 * fill, or misses one we expect, so a prompt edit can't silently drop context.
 * Values are inserted in a single pass, so user-controlled text containing
 * "{{...}}" is never expanded.
 */
export function fillPrompt(template: string, values: PromptValues): string {
  const found = new Set([...template.matchAll(/\{\{([A-Z_]+)\}\}/g)].map((m) => m[1]));
  const expected = new Set<string>(PROMPT_PLACEHOLDERS);
  const unknown = [...found].filter((p) => !expected.has(p));
  const missing = [...expected].filter((p) => !found.has(p));
  if (unknown.length || missing.length) {
    throw new Error(`System prompt placeholders mismatch. Unknown: ${unknown.join(',')} Missing: ${missing.join(',')}`);
  }
  return template.replace(/\{\{([A-Z_]+)\}\}/g, (_, key: keyof PromptValues) => values[key]);
}
