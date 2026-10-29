const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { test } = require("node:test");
const { randomUUID } = require("node:crypto");
const vm = require("node:vm");
const { indexedDB } = require("fake-indexeddb");

const source = readFileSync("web/centinela_storage.js", "utf8");
let now = 1000000;

function tab(storage = new Map(), navigationType = "navigate") {
  const sessionStorage = { getItem: (key) => storage.get(key) || null,
    setItem: (key, value) => storage.set(key, value) };
  const performance = { getEntriesByType: () => [{ type: navigationType }] };
  const context = vm.createContext({ indexedDB, crypto: { randomUUID }, Date: { now: () => now },
    sessionStorage, performance });
  vm.runInContext(source, context);
  return context.CentinelaStorage;
}

let requestNumber = 0;
function send(client, operation, payload = {}, requestId = `TEST_ONLY_${++requestNumber}`) {
  return new Promise((resolve) => {
    client.request(JSON.stringify({ protocol_version: 1, request_id: requestId, operation, payload }),
      (raw) => resolve(JSON.parse(raw)));
  });
}

function snapshot(slot, phase = "bedroom") {
  return { schema_version: 1, narrative_version: "TEST_ONLY", slot,
    code: `CTN-${String(slot).padStart(6, "0")}`, phase, flags: {}, player_position: [1, 2], phone_messages: [] };
}

async function outboxCount() {
  const db = await new Promise((resolve, reject) => {
    const request = indexedDB.open("centinela_2_local_v1");
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  const count = await new Promise((resolve, reject) => {
    const request = db.transaction("event_outbox").objectStore("event_outbox").count();
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  db.close();
  return count;
}

test("ranuras, bloqueo, transacción de decisión e idempotencia", async () => {
  const firstSession = new Map();
  const first = tab(firstSession);
  const second = tab();
  assert.equal((await send(first, "list_slots")).result.length, 0);

  const acquired = await send(first, "acquire_lock", { slot: 1 });
  assert.equal(acquired.success, true);
  assert.equal(acquired.result.generation, 1);
  const firstWrite = { slot: 1, generation: 1, snapshot: snapshot(1) };
  const committed = await send(first, "save_snapshot", firstWrite, "TEST_ONLY_save_1");
  assert.equal(committed.success, true);
  assert.equal((await send(first, "load_slot", { slot: 1 })).result.phase, "bedroom");
  const guided = { ...snapshot(1, "computer"), flags: { d0_guide_active: "computer" } };
  assert.equal((await send(first, "save_snapshot", { slot: 1, generation: 1, snapshot: guided })).success, true);
  assert.equal((await send(first, "load_slot", { slot: 1 })).result.flags.d0_guide_active, "computer");
  const desktop = { ...snapshot(1, "computer"), ui_modal: "desktop" };
  assert.equal((await send(first, "save_snapshot", { slot: 1, generation: 1, snapshot: desktop })).success, true);
  assert.equal((await send(first, "load_slot", { slot: 1 })).result.ui_modal, "desktop");
  assert.equal((await send(first, "save_snapshot", firstWrite)).success, true);
  for (const draftVersion of ["PLAYABLE_DRAFT_v0.1", "PLAYABLE_DRAFT_v0.2", "PLAYABLE_DRAFT_v0.3"]) {
    const draft = { ...snapshot(1, "preview"), flags: { draft_mode: true },
      draft_content_version: draftVersion,
      preview_scene: draftVersion === "PLAYABLE_DRAFT_v0.1" ? "D3_01_A" :
        draftVersion === "PLAYABLE_DRAFT_v0.3" ? "D1_03_A" : "D2_04_A", preview_step: 0 };
    assert.equal((await send(first, "save_snapshot", { slot: 1, generation: 1, snapshot: draft })).success, true);
  }
  const dailyIntro = { ...snapshot(1, "preview"), flags: { draft_mode: true,
    draft_exploring: true, draft_intro_step: 0 }, draft_content_version: "PLAYABLE_DRAFT_v0.3",
    preview_scene: "D1_02_A", preview_step: 0 };
  assert.equal((await send(first, "save_snapshot", { slot: 1, generation: 1, snapshot: dailyIntro })).success, true);
  const coral = { ...snapshot(1, "coral"), coral_state: { version: "CORAL_STORY_v0.1",
    day: 2, mode: "scene", node: "D2_B", step: 3, route: "B", branch: "",
    choices: { D1_GATE: "B" }, companion_states: {}, actions: ["D1_TALK_CAMILA", "D1_TALK_MATEO"],
    observed: [], seen_narrator: ["D1_INTRO_0"], hint_requests: { "1": "h1" },
    adult_support_started: false, limit_completed: false, chapter_scene_done: false, ending: "" } };
  assert.equal((await send(first, "save_snapshot", { slot: 1, generation: 1, snapshot: coral })).success, true);
  assert.equal((await send(first, "load_slot", { slot: 1 })).result.coral_state.node, "D2_B");
  const ensemble = { ...coral, coral_state: { ...coral.coral_state, version: "CORAL_STORY_v0.2", node: "I_D2_BRUNO" } };
  assert.equal((await send(first, "save_snapshot", { slot: 1, generation: 1, snapshot: ensemble })).success, true);
  assert.equal((await send(first, "load_slot", { slot: 1 })).result.coral_state.node, "I_D2_BRUNO");
  assert.equal((await send(first, "save_snapshot", { slot: 1, generation: 1,
    snapshot: { ...coral, coral_state: { ...coral.coral_state, companion_states: [] } } })).error.code, "INVALID_REQUEST");
  assert.equal((await send(first, "save_snapshot", firstWrite)).success, true);
  for (const malformed of [
    { ...snapshot(1), code: "CTN-+12345" },
    { ...snapshot(1), player_position: [Infinity, 2] },
    { ...snapshot(1), flags: { alarm: "sí" } },
    { ...snapshot(1), flags: { d0_guide_active: "computer" } },
    { ...snapshot(1), flags: { draft_mode: true } },
    { ...snapshot(1), flags: { draft_mode: true, draft_exploring: true },
      draft_content_version: "PLAYABLE_DRAFT_v0.1" },
    { ...snapshot(1, "preview"), flags: { draft_mode: true, draft_intro_step: 1 },
      draft_content_version: "PLAYABLE_DRAFT_v0.3", preview_scene: "D1_02_A" },
    { ...snapshot(1), flags: { draft_ending: "F99" } },
    { ...snapshot(1), phone_messages: [42] },
    { ...snapshot(1), moba_class: "desconocida" },
    { ...snapshot(1), preview_step: 1.5 },
    { ...snapshot(1), dialogue_key: "wakeup", dialogue_position: 8 },
    { ...snapshot(1), ui_modal: "class" },
    { ...snapshot(1), ui_modal: "desktop" },
    { ...snapshot(1), text_size: "enorme" },
    { ...snapshot(1), music_volume: 30 }
  ]) {
    assert.equal((await send(first, "save_snapshot", { slot: 1, generation: 1,
      snapshot: malformed })).error.code, "INVALID_REQUEST");
    assert.equal((await send(first, "load_slot", { slot: 1 })).result.phase, "bedroom");
  }
  assert.equal(await outboxCount(), 0);
  assert.deepEqual((await send(first, "save_snapshot", firstWrite, "TEST_ONLY_save_1")).result, committed.result);
  assert.equal((await send(first, "save_snapshot", { ...firstWrite, snapshot: snapshot(1, "courtyard") }, "TEST_ONLY_save_1")).error.code, "INVALID_REQUEST");
  const reloaded = tab(firstSession, "reload");
  assert.equal((await send(reloaded, "acquire_lock", { slot: 1 })).result.generation, 1);
  assert.equal((await send(second, "acquire_lock", { slot: 1 })).error.code, "LOCK_HELD");

  now += 31000;
  const takeover = await send(second, "acquire_lock", { slot: 1 });
  assert.equal(takeover.result.generation, 2);
  assert.equal((await send(first, "save_snapshot", { ...firstWrite, snapshot: snapshot(1, "courtyard") })).error.code, "LOCK_LOST");
  const newWrite = await send(second, "save_snapshot", { slot: 1, generation: 2, snapshot: snapshot(1, "courtyard") });
  assert.equal(newWrite.success, true);
  assert.equal((await send(second, "load_slot", { slot: 1 })).result.phase, "courtyard");

  const slotTwo = await send(first, "acquire_lock", { slot: 2 });
  assert.equal(slotTwo.result.generation, 1);
  assert.equal((await send(first, "save_snapshot", { slot: 2, generation: 1, snapshot: snapshot(2) })).success, true);
  assert.equal((await send(second, "list_slots")).result.length, 2);

  const decision = { slot: 1, generation: 2, snapshot: snapshot(1, "computer"),
    event: { event_id: "TEST_ONLY_event_1", decision_id: "TEST_ONLY_D0",
      choice_id: "TEST_ONLY_choice", kind: "decision", sequence: 1 } };
  assert.equal((await send(second, "save_decision_atomic", { ...decision,
    snapshot: { ...decision.snapshot, phone_messages: [42] } })).error.code, "INVALID_REQUEST");
  assert.equal(await outboxCount(), 0);
  assert.equal((await send(second, "load_slot", { slot: 1 })).result.phase, "courtyard");
  const decisionResult = await send(second, "save_decision_atomic", decision, "TEST_ONLY_decision_1");
  assert.equal(decisionResult.success, true);
  assert.equal(decisionResult.result.sequence, 1);
  assert.equal(await outboxCount(), 1);
  assert.equal((await send(second, "save_decision_atomic", decision, "TEST_ONLY_decision_1")).result.sequence, 1);
  assert.equal(await outboxCount(), 1);

  const invalidSequence = { ...decision, snapshot: snapshot(1, "result"),
    event: { ...decision.event, event_id: "TEST_ONLY_event_2", sequence: 3 } };
  assert.equal((await send(second, "save_decision_atomic", invalidSequence)).error.code, "INVALID_REQUEST");
  assert.equal((await send(second, "load_slot", { slot: 1 })).result.phase, "computer");
  assert.equal(await outboxCount(), 1);

  const reusedEvent = { ...decision, snapshot: snapshot(1, "result"),
    event: { ...decision.event, sequence: 2 } };
  assert.equal((await send(second, "save_decision_atomic", reusedEvent)).error.code, "INVALID_REQUEST");
  assert.equal(await outboxCount(), 1);

  const credential = { registration_id: "TEST_ONLY_registration", save_id: "TEST_ONLY_save",
    recovery_secret: "TEST_ONLY_secret" };
  assert.equal((await send(second, "put_credential", { slot: 1, generation: 2, credential })).success, true);
  assert.deepEqual((await send(second, "get_credential", { slot: 1, generation: 2 })).result, credential);
  assert.equal((await send(first, "get_credential", { slot: 1, generation: 1 })).error.code, "LOCK_LOST");
  const queued = await send(second, "peek_outbox", { slot: 1, generation: 2 });
  assert.equal(queued.result.length, 1);
  assert.equal(queued.result[0].event_id, decision.event.event_id);
  assert.equal((await send(second, "ack_outbox", { slot: 1, generation: 2,
    receipts: [{ event_id: decision.event.event_id, status: "missing_sequence" }] })).result.acknowledged, 0);
  assert.equal((await send(second, "peek_outbox", { slot: 1, generation: 2 })).result.length, 1);
  assert.equal((await send(second, "ack_outbox", { slot: 1, generation: 2,
    receipts: [{ event_id: decision.event.event_id, status: "accepted" }] })).result.acknowledged, 1);
  assert.equal((await send(second, "peek_outbox", { slot: 1, generation: 2 })).result.length, 0);
  assert.equal((await send(second, "set_sync_status", { slot: 1, generation: 2,
    status: { last_sequence: 1, sync_completed: false } })).success, true);
  assert.equal((await send(second, "get_sync_status", { slot: 1, generation: 2 })).result.last_sequence, 1);

  const descriptive = { slot: 1, generation: 2, snapshot: snapshot(1, "result"),
    event: { event_id: "TEST_ONLY_moba", kind: "moba_result", sequence: 2 } };
  assert.equal((await send(second, "save_event_atomic", descriptive, "TEST_ONLY_moba_request")).success, true);
  assert.equal((await send(second, "peek_outbox", { slot: 1, generation: 2 })).result[0].kind, "moba_result");
  assert.equal((await send(second, "ack_outbox", { slot: 1, generation: 2,
    receipts: [{ event_id: "TEST_ONLY_moba", status: "accepted" }] })).result.acknowledged, 1);
  assert.equal((await send(second, "save_event_atomic", descriptive, "TEST_ONLY_moba_request")).success, true);
  assert.equal((await send(second, "peek_outbox", { slot: 1, generation: 2 })).result.length, 0);

  assert.equal((await send(second, "release_lock", { slot: 1, generation: 2 })).success, true);
  assert.equal((await send(second, "acquire_lock", { slot: 1 })).result.generation, 3);
  assert.equal((await send(second, "save_snapshot", { slot: 1, generation: 2, snapshot: snapshot(1, "result") })).error.code, "LOCK_LOST");
  assert.equal((await send(second, "renew_lock", { slot: 1, generation: 3 })).success, true);
  assert.equal((await send(second, "save_event_atomic", { slot: 1, generation: 3,
    snapshot: snapshot(1, "result"), event: { event_id: "TEST_ONLY_pending", kind: "moba_result", sequence: 3 } })).success, true);
  assert.equal(await outboxCount(), 1);
  const freshGame = { ...snapshot(1), code: "CTN-999999" };
  const reset = await send(second, "reset_slot", { slot: 1, generation: 3, snapshot: freshGame });
  assert.equal(reset.success, true);
  assert.notEqual(reset.result.save_id, committed.result.save_id);
  assert.equal(reset.result.sequence, 0);
  assert.equal((await send(second, "load_slot", { slot: 1 })).result.code, freshGame.code);
  assert.equal((await send(second, "list_slots")).result.find((entry) => entry.slot === 1).sequence, 0);
  assert.equal(await outboxCount(), 0);
  assert.equal((await send(second, "save_snapshot", { slot: 1, generation: 3, snapshot: freshGame })).error.code, "LOCK_LOST");
  assert.equal((await send(first, "delete_slot", { slot: 1, generation: 1 })).error.code, "LOCK_LOST");
  const freshLock = await send(second, "acquire_lock", { slot: 1 });
  assert.equal(freshLock.result.generation, 4);
  assert.equal((await send(second, "get_credential", { slot: 1, generation: 4 })).result, null);
  assert.equal((await send(second, "get_sync_status", { slot: 1, generation: 4 })).result, null);
  assert.equal((await send(second, "save_snapshot", { slot: 1, generation: 4,
    snapshot: freshGame }, "TEST_ONLY_decision_1")).success, true);
  assert.equal((await send(second, "delete_slot", { slot: 1, generation: 4 })).success, true);
  assert.equal((await send(second, "load_slot", { slot: 1 })).result, null);
  assert.equal((await send(second, "list_slots")).result.length, 1);
  assert.equal((await send(second, "list_slots")).result[0].slot, 2);
  assert.equal((await send(second, "delete_slot", { slot: 1, generation: 4 })).error.code, "LOCK_LOST");
  assert.equal((await send(second, "unknown")).error.code, "INVALID_REQUEST");
});
