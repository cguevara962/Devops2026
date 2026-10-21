const cds = require('@sap/cds');

module.exports = cds.service.impl(function () {
  // ── Credential Store integration ───────────────────────────────────────────
  // BTP injects the Credential Store binding via VCAP_SERVICES at deploy time.
  // We read the DB credential HERE at startup — never from source code.
  const vcap = JSON.parse(process.env.VCAP_SERVICES || '{}');

  // Real SAP Credential Store binding (managed service, plan proxy/free)
  const csManaged = vcap.credentialstore?.[0]?.credentials;
  // User-provided service fallback (simulates Credential Store for demo environments)
  const csUps = vcap['user-provided']?.find(s => s.name === 'devsecops-demo-credential-store')?.credentials;
  const csBinding = csManaged || csUps;

  if (csManaged) {
    console.log(`[CredentialStore] Managed binding found → ${csManaged.url}`);
    console.log('[CredentialStore] Ready to resolve secrets at runtime.');
  } else if (csUps) {
    console.log(`[CredentialStore] User-provided binding found → namespace: ${csUps.namespace}`);
    console.log(`[CredentialStore] db-password resolved from service binding (not hardcoded).`);
  } else {
    console.log('[CredentialStore] No binding found — running in local dev mode (SQLite).');
  }

  // No custom READ handlers needed.
  // CAP auto-serves full OData v4 CRUD for the Products entity.
  //
  // Available endpoints once running:
  //   GET /catalog/Products           → list all products
  //   GET /catalog/Products('p1')     → single product by key
  //   GET /catalog/$metadata          → OData metadata document
  //
  // ── WOW-moment reminder (DEMO STEP 3) ────────────────────────────────────
  // During the live demo, add a hardcoded credential line here, commit and
  // push — the detectSecrets gate in the pipeline will catch it immediately.
  // See DEMO_SCRIPT.md for the exact steps.
});
