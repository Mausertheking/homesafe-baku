import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { bucket } from './admin.js';
import { TIME_ZONE } from './config.js';

/** Generated files that only need to live long enough to be downloaded. */
export const TEMP_PREFIXES = ['reports/', 'letters/', 'exports/'];
export const TEMP_MAX_AGE_MS = 24 * 60 * 60 * 1000;

export function isExpired(created: string | undefined, now: number): boolean {
  if (!created) return false;
  return now - new Date(created).getTime() > TEMP_MAX_AGE_MS;
}

/**
 * cleanupTempFiles: every night, deletes PDF reports, letter PDFs and data
 * exports older than one day (privacy policy: "files are deleted after one
 * day"). Evidence photos are never touched.
 */
export const cleanupTempFiles = onSchedule({ schedule: '30 3 * * *', timeZone: TIME_ZONE }, async () => {
  const now = Date.now();
  let deleted = 0;
  for (const prefix of TEMP_PREFIXES) {
    const [files] = await bucket().getFiles({ prefix });
    for (const f of files) {
      if (isExpired(f.metadata.timeCreated, now)) {
        await f.delete({ ignoreNotFound: true });
        deleted++;
      }
    }
  }
  logger.info('temp files cleaned', { deleted });
});
