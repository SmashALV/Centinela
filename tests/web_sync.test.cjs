const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { randomUUID } = require("node:crypto");
const { test } = require("node:test");
const vm = require("node:vm");
const { indexedDB } = require("fake-indexeddb");

const storageSource = readFileSync("web/centinela_storage.js", "utf8");
const syncSource = readFileSync("web/centinela_sync.js", "utf8");
let requestNumber = 0;

function send(api, operation, payload = {}) {
  return new Promise((resolve) => api.request(JSON.stringify({ protocol_version: 1,
    request_id: `TEST_ONLY_${++requestNumber}`, operation, payload }),
  (raw) => resolve(JSON.parse(raw))));
}

function snapshot() {
  return { schema_version: 1, narrative_version: "TEST_ONLY_NARRATIVE", slot: 1,
    code: "CTN-555555", phase: "result", flags: {}, player_position: [1, 2], phone_messages: [] };
}

test("P4 Web: registro recuperable, acuses parciales y reclamo", async () => {
  const calls = [];
  let failRegister = true;
  let rejectSecond = false;
  let expireOnce = true;
  const fetch = async (url, options) => {
    const body = JSON.parse(options.body);
    calls.push({ url, body, authorization: options.headers.Authorization });
    if (url.endsWith("/auth/v1/signup"))
      return { ok: true, json: async () => ({ access_token: `TEST_ONLY_jwt_${calls.length}`,
        refresh_token: "TEST_ONLY_refresh" }) };
    if (url.includes("/auth/v1/token?grant_type=refresh_token"))
      return { ok: true, json: async () => ({ access_token: "TEST_ONLY_refreshed_jwt",
        refresh_token: "TEST_ONLY_refreshed_token" }) };
    if (url.endsWith("/register_save") && failRegister) {
      failRegister = false;
      throw new Error("TEST_ONLY_disconnect");
    }
    if (url.endsWith("/register_save"))
      return { ok: true, json: async () => ({ save_id: "TEST_ONLY_SAVE",
        code: "CTN-444444", recovery_secret: "TEST_ONLY_SECRET" }) };
    if (url.endsWith("/claim_save"))
      return { ok: true, json: async () => ({ save_id: "TEST_ONLY_SAVE",
        code: "CTN-444444", last_sequence: 0 }) };
    if (url.endsWith("/ingest_events") && expireOnce) {
      expireOnce = false;
      return { ok: false, status: 401, json: async () => ({ error: "expired" }) };
    }
    if (url.endsWith("/ingest_events"))
      return { ok: true, json: async () => ({ last_sequence: rejectSecond ? 1 : 2,
        sync_completed: false, receipts: body.events.map((event) => ({ event_id: event.event_id,
          status: rejectSecond && event.sequence === 2 ? "missing_sequence" : "accepted" })) }) };
    throw new Error(`Unexpected request: ${url}`);
  };
  const context = vm.createContext({ indexedDB, fetch, crypto: { randomUUID }, URL,
    AbortController, setTimeout, clearTimeout, Date, sessionStorage: {
      getItem: () => null, setItem: () => {} }, performance: {
      getEntriesByType: () => [{ type: "navigate" }] } });
  vm.runInContext(storageSource, context);
  vm.runInContext(syncSource, context);
  const storage = context.CentinelaStorage;
  const sync = context.CentinelaSync;
  const lock = (await send(storage, "acquire_lock", { slot: 1 })).result;
  assert.equal((await send(storage, "save_snapshot", { slot: 1, generation: lock.generation,
    snapshot: snapshot() })).success, true);
  const config = { url: "http://localhost:54321", public_key: "TEST_ONLY_PUBLIC",
    rubric_version: "TEST_ONLY_RUBRIC" };
  const openPayload = { slot: 1, generation: lock.generation, code: "CTN-555555",
    narrative_version: "TEST_ONLY_NARRATIVE", config };
  assert.equal((await send(sync, "sync_open", openPayload)).error.code, "OFFLINE");
  const pending = (await send(storage, "get_credential", { slot: 1, generation: lock.generation })).result;
  assert.equal(typeof pending.registration_id, "string");
  assert.equal(pending.recovery_secret, undefined);
  const opened = await send(sync, "sync_open", openPayload);
  assert.equal(opened.success, true);
  assert.equal(opened.result.code, "CTN-444444");
  const registrations = calls.filter((call) => call.url.endsWith("/register_save"));
  assert.equal(registrations.length, 2);
  assert.equal(registrations[0].body.registration_id, registrations[1].body.registration_id);
  const credential = (await send(storage, "get_credential", { slot: 1, generation: lock.generation })).result;
  assert.equal(credential.recovery_secret, "TEST_ONLY_SECRET");
  assert.equal(credential.registration_id, undefined);
  assert.equal((await send(storage, "load_slot", { slot: 1 })).result.recovery_secret, undefined);

  const firstEvent = { event_id: randomUUID(), sequence: 1, kind: "moba_result",
    narrative_version: "TEST_ONLY_NARRATIVE", rubric_version: "TEST_ONLY_RUBRIC",
    day: 0, scene: "moba", occurred_at: "2026-10-27T12:00:00Z", context: { result: "draw" } };
  const secondEvent = { ...firstEvent, event_id: randomUUID(), sequence: 2 };
  for (const event of [firstEvent, secondEvent]) {
    assert.equal((await send(storage, "save_event_atomic", { slot: 1,
      generation: lock.generation, snapshot: snapshot(), event })).success, true);
  }
  rejectSecond = true;
  assert.equal((await send(sync, "sync_flush", { slot: 1, generation: lock.generation })).error.code,
    "EVENT_REJECTED");
  const remaining = (await send(storage, "peek_outbox", { slot: 1, generation: lock.generation })).result;
  assert.equal(remaining.length, 1);
  assert.equal(remaining[0].event_id, secondEvent.event_id);
  assert.equal((await send(storage, "get_sync_status", { slot: 1,
    generation: lock.generation })).result.last_error, "missing_sequence");
  assert.equal(calls.filter((call) => call.url.includes("/auth/v1/token?grant_type=refresh_token")).length, 1);
  rejectSecond = false;
  assert.equal((await send(sync, "sync_flush", { slot: 1, generation: lock.generation })).success, true);
  assert.equal((await send(storage, "peek_outbox", { slot: 1, generation: lock.generation })).result.length, 0);

  await send(sync, "sync_close", { slot: 1, generation: lock.generation });
  assert.equal((await send(sync, "sync_open", openPayload)).success, true);
  assert.equal(calls.filter((call) => call.url.endsWith("/claim_save")).length, 1);
});
