const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { test } = require("node:test");
const { randomUUID } = require("node:crypto");
const { PGlite } = require("@electric-sql/pglite");

const migration = readFileSync("supabase/migrations/20261027000100_p4_core.sql", "utf8");
const seed = readFileSync("supabase/seed.sql", "utf8");
const rubric = "TEST_ONLY_P4_v1";
const narrative = "provisional-d0-1";
const secretHash = "a".repeat(64);

async function call(db, name, args) {
  const placeholders = args.map((_, index) => `$${index + 1}`).join(", ");
  const result = await db.query(`select public.${name}(${placeholders}) as value`, args);
  return result.rows[0].value;
}

test("P4 SQL: propiedad, idempotencia, secuencia y puntuación solo servidor", async () => {
  const db = new PGlite();
  try {
    await db.exec("create role anon; create role authenticated; create role service_role; create schema auth; create table auth.users(id uuid primary key);");
    await db.exec(migration);
    await db.exec(seed);
    const ownerA = randomUUID();
    const ownerB = randomUUID();
    await db.query("insert into auth.users(id) values ($1), ($2)", [ownerA, ownerB]);

    const registrationId = randomUUID();
    await assert.rejects(() => call(db, "centinela_register_save", [ownerA, registrationId,
      "CTN-123456", narrative, rubric, secretHash, false]));
    const registered = await call(db, "centinela_register_save", [ownerA, registrationId, "CTN-123456", narrative, rubric, secretHash, true]);
    assert.equal(registered.code, "CTN-123456");
    assert.deepEqual(await call(db, "centinela_register_save", [ownerA, registrationId, "CTN-123456", narrative, rubric, secretHash, true]), registered);
    const saveId = registered.save_id;
    const common = { narrative_version: narrative, rubric_version: rubric,
      day: 1, scene: "TEST_ONLY_SCENE", occurred_at: "2026-10-27T12:00:00Z" };
    const event = { ...common, event_id: randomUUID(), sequence: 1, kind: "decision",
      decision_id: "TEST_ONLY_D1", choice_id: "TEST_ONLY_SAFE",
      context: {} };
    const gap = { ...event, event_id: randomUUID(), sequence: 3 };
    const first = await call(db, "centinela_ingest_events", [ownerA, saveId, JSON.stringify([gap, event])]);
    assert.deepEqual(first.receipts.map((item) => item.status), ["missing_sequence", "accepted"]);
    assert.equal(first.last_sequence, 1);
    assert.equal((await call(db, "centinela_ingest_events", [ownerA, saveId, JSON.stringify([event])])).receipts[0].status, "duplicate");
    const changedDuplicate = { ...event, choice_id: "TEST_ONLY_OTHER" };
    assert.equal((await call(db, "centinela_ingest_events", [ownerA, saveId,
      JSON.stringify([changedDuplicate])])).receipts[0].status, "event_id_conflict");
    const repeatedDecision = { ...event, event_id: randomUUID(), sequence: 2,
      choice_id: "TEST_ONLY_OTHER" };
    assert.equal((await call(db, "centinela_ingest_events", [ownerA, saveId,
      JSON.stringify([repeatedDecision])])).receipts[0].status, "decision_conflict");
    const personalData = { ...event, event_id: randomUUID(), sequence: 2, student_name: "TEST_ONLY_NAME" };
    assert.equal((await call(db, "centinela_ingest_events", [ownerA, saveId,
      JSON.stringify([personalData])])).receipts[0].status, "invalid_event");
    const badMoba = { ...common, event_id: randomUUID(), sequence: 2,
      kind: "moba_result", context: { result: null } };
    assert.equal((await call(db, "centinela_ingest_events", [ownerA, saveId,
      JSON.stringify([badMoba])])).receipts[0].status, "invalid_event");
    const score = await db.query("select score_pct, awarded_points from centinela_private.educational_scores where save_id=$1 and dimension='D1'", [saveId]);
    assert.equal(Number(score.rows[0].score_pct), 100);
    assert.equal(score.rows[0].awarded_points, 2);
    await assert.rejects(() => db.query("update centinela_private.rubric_items set points=0 where rubric_version=$1", [rubric]));
    const global = await db.query("select global_pct from centinela_private.educational_global_scores where save_id=$1", [saveId]);
    assert.equal(global.rows[0].global_pct, null);

    await assert.rejects(() => call(db, "centinela_ingest_events", [ownerB, saveId, JSON.stringify([event])]));
    await assert.rejects(() => call(db, "centinela_claim_save", [ownerB, saveId, "b".repeat(64)]));
    const claimed = await call(db, "centinela_claim_save", [ownerB, saveId, secretHash]);
    assert.equal(claimed.last_sequence, 1);
    await assert.rejects(() => call(db, "centinela_ingest_events", [ownerA, saveId, JSON.stringify([event])]));
    const pending = await call(db, "centinela_finalize_sync", [ownerB, saveId, 2]);
    assert.equal(pending.sync_completed, false);
    const second = { ...common, event_id: randomUUID(), sequence: 2, kind: "moba_result",
      context: { result: "draw" } };
    const accepted = await call(db, "centinela_ingest_events", [ownerB, saveId, JSON.stringify([second])]);
    assert.equal(accepted.receipts[0].status, "accepted");
    assert.equal(accepted.sync_completed, true);
    const repeatedResult = { ...second, event_id: randomUUID(), sequence: 3 };
    assert.equal((await call(db, "centinela_ingest_events", [ownerB, saveId,
      JSON.stringify([repeatedResult])])).receipts[0].status, "after_finalization");
    assert.equal((await db.query("select count(*)::int as n from centinela_private.game_events where save_id=$1", [saveId])).rows[0].n, 2);
    const completeSave = await call(db, "centinela_register_save", [ownerB, randomUUID(),
      "CTN-654321", narrative, rubric, "b".repeat(64), true]);
    const collisionRegistration = randomUUID();
    const collisionSave = await call(db, "centinela_register_save", [ownerB, collisionRegistration,
      "CTN-123456", narrative, rubric, "c".repeat(64), true]);
    assert.match(collisionSave.code, /^CTN-[0-9]{6}$/);
    assert.notEqual(collisionSave.code, "CTN-123456");
    assert.deepEqual(await call(db, "centinela_register_save", [ownerB, collisionRegistration,
      "CTN-123456", narrative, rubric, "c".repeat(64), true]), collisionSave);
    const dimensions = ["D1", "D2", "D3", "D4"];
    const educationalEvents = dimensions.map((dimension, index) => ({ ...common,
      event_id: randomUUID(), sequence: index + 1, kind: "decision",
      decision_id: `TEST_ONLY_${dimension}`,
      choice_id: index % 2 === 0 ? "TEST_ONLY_SAFE" : "TEST_ONLY_OTHER", context: {} }));
    const completeReceipt = await call(db, "centinela_ingest_events", [ownerB, completeSave.save_id,
      JSON.stringify(educationalEvents)]);
    assert.deepEqual(completeReceipt.receipts.map((item) => item.status),
      ["accepted", "accepted", "accepted", "accepted"]);
    const completeScore = await db.query("select global_pct from centinela_private.educational_global_scores where save_id=$1", [completeSave.save_id]);
    assert.equal(Number(completeScore.rows[0].global_pct), 50);
    await db.query("select centinela_private.consume_rate($1,'TEST_ONLY_RATE',2)", [ownerB]);
    await db.query("select centinela_private.consume_rate($1,'TEST_ONLY_RATE',2)", [ownerB]);
    await assert.rejects(() => db.query("select centinela_private.consume_rate($1,'TEST_ONLY_RATE',2)", [ownerB]),
      (error) => error.code === "P0001");
    await db.exec("set role anon");
    await assert.rejects(() => db.query("select * from centinela_private.participant_saves"));
    await assert.rejects(() => db.query("select public.centinela_finalize_sync($1,$2,2)", [ownerB, saveId]));
    await db.exec("reset role");
  } finally {
    await db.close();
  }
});
