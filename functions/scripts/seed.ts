/**
 * Seeds reference data: rules/*, legalTopics/*, letterTemplates/*, config/app.
 *
 *   Emulator:  FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=demo-homesafe npm run seed
 *   Real:      GOOGLE_APPLICATION_CREDENTIALS=... GCLOUD_PROJECT=<id> npm run seed
 *
 * Legal topics are created as EMPTY placeholders on purpose: the app shows
 * "being checked by a lawyer" until reviewed text is added.
 */
import { db } from '../src/admin.js';
import { LETTER_TEMPLATES } from '../src/letterTemplates.js';
import { ruleFiles } from '../src/rules.js';
import { readSharedJson } from '../src/shared.js';

const firestore = db();
const batch = firestore.batch();
let rulesVersion = 0;

for (const file of ruleFiles()) {
  rulesVersion = Math.max(rulesVersion, file.rulesVersion);
  for (const rule of file.rules) {
    batch.set(firestore.doc(`rules/${rule.id}`), {
      check: file.check,
      rule,
      version: rule.version,
      reviewed: rule.reviewed ?? false,
      reviewedBy: null, // TODO(chemical engineer)
      reviewedOn: null,
    });
  }
}

// DRAFT legal topics (shared/legal/rights.json): written from public law
// texts, NOT lawyer-reviewed. reviewedBy/reviewedOn stay null until a lawyer
// signs off; until then the app labels them "Draft" and the AI ignores them.
// TODO(lawyer): review, then set reviewedBy + reviewedOn per topic.
const rights = readSharedJson<{ topics: { id: string; order: number; title: unknown; body: unknown; lawReference: unknown; sources: string[] }[] }>('legal', 'rights.json');
const topics = rights.topics;
for (const t of topics) {
  batch.set(firestore.doc(`legalTopics/${t.id}`), {
    order: t.order,
    title: t.title,
    body: t.body,
    lawReference: t.lawReference,
    sources: t.sources,
    status: 'draft',
    reviewedBy: null,
    reviewedOn: null,
  }, { merge: true });
}

for (const [id, template] of Object.entries(LETTER_TEMPLATES)) {
  batch.set(firestore.doc(`letterTemplates/${id}`), template);
}

const emergency = readSharedJson<{ numbers: unknown[]; verified: boolean }>('emergency.json');
batch.set(firestore.doc('config/app'), {
  rulesVersion,
  emergencyNumbers: emergency.numbers, // TODO(team): verified numbers.
  emergencyNumbersVerified: emergency.verified,
  minAppVersion: '0.1.0',
}, { merge: true });

await batch.commit();
console.log(`Seeded rules (v${rulesVersion}), ${topics.length} draft legal topics, letter templates, config/app.`);
