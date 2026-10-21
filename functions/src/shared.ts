import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

/** The functions package root, found by walking up to package.json, so paths
 * work the same from src/ (tests) and lib/src/ (deployed). */
function packageRoot(): string {
  let dir = dirname(fileURLToPath(import.meta.url));
  while (!existsSync(join(dir, 'package.json'))) {
    const parent = dirname(dir);
    if (parent === dir) throw new Error('functions package.json not found');
    dir = parent;
  }
  return dir;
}

const ROOT = packageRoot();

/** Reads a file synced from the repository's shared/ folder (tool/sync_shared.sh). */
export function sharedPath(...parts: string[]): string {
  return join(ROOT, 'shared', ...parts);
}

export function readShared(...parts: string[]): string {
  return readFileSync(sharedPath(...parts), 'utf8');
}

export function readSharedJson<T>(...parts: string[]): T {
  return JSON.parse(readShared(...parts)) as T;
}

export function assetPath(...parts: string[]): string {
  return join(ROOT, 'assets', ...parts);
}

export const LANGUAGES = ['az', 'ru', 'en'] as const;
export type Language = (typeof LANGUAGES)[number];
export const isLanguage = (v: unknown): v is Language => typeof v === 'string' && (LANGUAGES as readonly string[]).includes(v);
