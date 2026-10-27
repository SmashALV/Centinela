const assert = require("node:assert/strict");
const { randomUUID, randomInt } = require("node:crypto");

const base = (process.env.CENTINELA_TEST_URL || "").replace(/\/+$/, "");
const publicKey = process.env.CENTINELA_TEST_PUBLIC_KEY || "";
if (process.env.CENTINELA_TEST_ENV !== "development" || !base || !publicKey) {
  console.error("Set CENTINELA_TEST_ENV=development, CENTINELA_TEST_URL and CENTINELA_TEST_PUBLIC_KEY.");
  process.exit(2);
}

async function request(path, body, jwt = "") {
  const response = await fetch(`${base}${path}`, { method: "POST",
    headers: { apikey: publicKey, "Content-Type": "application/json",
      ...(jwt ? { Authorization: `Bearer ${jwt}` } : {}) },
    body: JSON.stringify(body) });
  const data = await response.json().catch(() => ({}));
  return { status: response.status, data };
}

async function anonymous() {
  const result = await request("/auth/v1/signup", {});
  assert.equal(result.status, 200, "anonymous sign-in failed");
  assert.equal(typeof result.data.access_token, "string");
  return result.data.access_token;
}

async function main() {
  const first = await anonymous();
  const second = await anonymous();
  const code = `CTN-${String(randomInt(1000000)).padStart(6, "0")}`;
  const registration_id = randomUUID();
  const registration = { registration_id, code, narrative_version: "provisional-d0-1",
    rubric_version: "TEST_ONLY_P4_v1" };
  const created = await request("/functions/v1/register_save", registration, first);
  assert.equal(created.status, 200, "register_save failed");
  assert.equal(typeof created.data.save_id, "string");
  assert.equal(typeof created.data.recovery_secret, "string");
  const repeated = await request("/functions/v1/register_save", registration, first);
  assert.equal(repeated.status, 200);
  assert.deepEqual(repeated.data, created.data);
  const save_id = created.data.save_id;
  const wrong = await request("/functions/v1/claim_save", { save_id,
    recovery_secret: "A".repeat(43) }, second);
  assert.equal(wrong.status, 403);
  const claimed = await request("/functions/v1/claim_save", { save_id,
    recovery_secret: created.data.recovery_secret }, second);
  assert.equal(claimed.status, 200);
  const event = { event_id: randomUUID(), sequence: 1, kind: "moba_result",
    narrative_version: "provisional-d0-1", rubric_version: "TEST_ONLY_P4_v1",
    day: 0, scene: "moba", occurred_at: new Date().toISOString(),
    context: { result: "draw" } };
  const denied = await request("/functions/v1/ingest_events", { save_id, events: [event] }, first);
  assert.equal(denied.status, 403, "old owner retained write access");
  const ingested = await request("/functions/v1/ingest_events", { save_id, events: [event] }, second);
  assert.equal(ingested.status, 200);
  assert.equal(ingested.data.receipts[0].status, "accepted");
  const duplicate = await request("/functions/v1/ingest_events", { save_id, events: [event] }, second);
  assert.equal(duplicate.data.receipts[0].status, "duplicate");
  const finalized = await request("/functions/v1/finalize_sync", { save_id,
    last_sequence: 1 }, second);
  assert.equal(finalized.status, 200);
  assert.equal(finalized.data.sync_completed, true);
  console.log("PASS development E2E: Auth, register retry, claim, revoked owner, event receipt, finalize");
}

main().catch((error) => { console.error(error.message); process.exitCode = 1; });
