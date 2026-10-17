// One-off migration helper: switch Firebase email-link generation from the
// (shut down) Firebase Dynamic Links service to the Firebase Hosting domain.
//
// Usage:
//   npm i firebase-admin
//   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
//     node set-mobile-links-domain.mjs trackmycafe-prod
//
// The domain must be a Firebase Hosting domain already associated with the
// project (typically <PROJECT_ID>.firebaseapp.com), and it must also be listed
// under Authentication -> Settings -> Authorized domains.

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const projectId = process.argv[2];

if (!projectId) {
    console.error('Usage: node set-mobile-links-domain.mjs <projectId>');
    process.exit(1);
}

// The Admin SDK only accepts the enum values HOSTING_DOMAIN and
// FIREBASE_DYNAMIC_LINK_DOMAIN (not a raw domain string).
const domain = 'HOSTING_DOMAIN';

initializeApp({ credential: applicationDefault(), projectId });

try {
    const config = await getAuth()
        .projectConfigManager()
        .updateProjectConfig({ mobileLinksConfig: { domain } });
    console.log(`OK: mobileLinksConfig.domain = ${config.mobileLinksConfig?.domain ?? domain}`);
} catch (error) {
    console.error('Failed to update project config:', error);
    process.exit(1);
}
