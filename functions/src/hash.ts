import { createHash } from 'node:crypto';
import type { Readable } from 'node:stream';

/** Bump if the canonical form ever changes; stored with every hash. */
export const HASH_VERSION = 1;

export interface TextEvidence {
  itemId: string;
  type: string;
  text: string;
  checkId?: string | null;
  letterId?: string | null;
}

/**
 * Canonical input for non-file evidence: a JSON array in fixed order, so the
 * same item always produces the same hash and anyone can recompute it:
 *   sha256(JSON.stringify([1, itemId, type, text, checkId|null, letterId|null]))
 */
export function canonicalText(e: TextEvidence): string {
  return JSON.stringify([HASH_VERSION, e.itemId, e.type, e.text, e.checkId ?? null, e.letterId ?? null]);
}

export function sha256Text(e: TextEvidence): string {
  return createHash('sha256').update(canonicalText(e), 'utf8').digest('hex');
}

/** Streams a file (e.g. from Cloud Storage) through SHA-256. */
export function sha256Stream(stream: Readable): Promise<{ sha256: string; size: number }> {
  return new Promise((resolve, reject) => {
    const hash = createHash('sha256');
    let size = 0;
    stream.on('data', (chunk: Buffer) => {
      size += chunk.length;
      hash.update(chunk);
    });
    stream.on('error', reject);
    stream.on('end', () => resolve({ sha256: hash.digest('hex'), size }));
  });
}
