// Run locally: node run_seed.js
// Requires: GOOGLE_APPLICATION_CREDENTIALS or firebase-admin default creds
const admin = require("firebase-admin");
const { seedWC2026 } = require("./lib/scripts/seed_wc2026");

admin.initializeApp({ projectId: "cdm26-33366" });

seedWC2026()
  .then(() => { console.log("Done!"); process.exit(0); })
  .catch((e) => { console.error(e); process.exit(1); });
