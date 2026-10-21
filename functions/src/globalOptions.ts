import { setGlobalOptions } from 'firebase-functions/v2';

import { REGION } from './config.js';

// Imported FIRST by index.ts. ES modules evaluate imports before the importing
// module's body, so calling setGlobalOptions in index.ts itself would run
// after every function was already defined (they would land in us-central1).
setGlobalOptions({ region: REGION, maxInstances: 20 });
