import { logger } from 'firebase-functions';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { messaging } from './admin.js';
import { TIME_ZONE } from './config.js';
import { strings } from './i18n.js';
import { LANGUAGES } from './shared.js';

/** 10:00 Baku time on the 1st of October to April. */
export const SEASONAL_SCHEDULE = '0 10 1 1-4,10-12 *';

/**
 * seasonalReminder: monthly push in the heating season, sent to the
 * per-language topics the app subscribes to (seasonal_az / _ru / _en).
 * No tokens or personal data are stored on the server.
 */
export const seasonalReminder = onSchedule({ schedule: SEASONAL_SCHEDULE, timeZone: TIME_ZONE }, async () => {
  for (const lang of LANGUAGES) {
    const t = strings(lang);
    await messaging().send({
      topic: `seasonal_${lang}`,
      notification: { title: t('push.seasonal.title'), body: t('push.seasonal.body') },
      android: { priority: 'normal' },
    });
  }
  logger.info('seasonal reminder sent');
});
