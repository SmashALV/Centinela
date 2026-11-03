const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { randomUUID } = require("node:crypto");
const { test } = require("node:test");
const { PGlite } = require("@electric-sql/pglite");

const p4 = readFileSync("supabase/migrations/20261027000100_p4_core.sql", "utf8");
const p6 = readFileSync("supabase/migrations/20261027000200_p6_research.sql", "utf8");
const telemetry = readFileSync("supabase/migrations/20261031000100_gameplay_telemetry.sql", "utf8");
const seed = readFileSync("supabase/seed.sql", "utf8");
const rubric = "DESCRIPTIVE_ONLY_v1";
const narrative = "provisional-d0-1";

async function call(db, name, args) {
  const placeholders = args.map((_, index) => `$${index + 1}`).join(", ");
  const result = await db.query(`select public.${name}(${placeholders}) as value`, args);
  return result.rows[0].value;
}

test("Telemetría SQL: tipos descriptivos, contexto estricto, MOBA diario y resumen", async () => {
  const db = new PGlite();
  try {
    await db.exec("create role anon; create role authenticated; create role service_role; create schema auth; create table auth.users(id uuid primary key);");
    await db.exec(p4);
    await db.exec(p6);
    await db.exec(telemetry);
    await db.exec(seed);
    const owner = randomUUID();
    await db.query("insert into auth.users(id) values ($1)", [owner]);
    // La versión descriptiva no requiere ALLOW_TEST_RUBRIC.
    const save = await call(db, "centinela_register_save", [owner, randomUUID(), "CTN-424242",
      narrative, rubric, "b".repeat(64), false]);
    let sequence = 0;
    const event = (kind, day, scene, context) => ({ event_id: randomUUID(), sequence: ++sequence,
      kind, narrative_version: narrative, rubric_version: rubric, day, scene,
      occurred_at: "2026-10-31T15:00:00Z", context });
    const ingest = (events) => call(db, "centinela_ingest_events_with_audit", [owner, save.save_id, JSON.stringify(events)]);

    const batch = [
      event("session_start", 0, "bedroom", { platform: "web", build: "0.40.0-preview", resumed: false }),
      event("day_start", 0, "D0", {}),
      event("moba_result", 0, "moba", { result: "victory" }),
      event("day_start", 1, "D1", {}),
      event("scene_start", 1, "D1_GATE", {}),
      event("story_choice", 1, "D1_GATE", { decision_id: "D1_GATE", choice_id: "C", behavior: "riesgo" }),
      event("story_action", 1, "D1_B_FOLLOW", { action: "D1_LOBBY_DONE" }),
      event("hint_request", 1, "D1", { level: "h1" }),
      event("pause", 1, "coral", {}),
      event("inactivity", 1, "coral", { mode: "exploration", duration_s: 95 }),
    ];
    const first = await ingest(batch);
    assert.deepEqual(first.receipts.map((receipt) => receipt.status), Array(10).fill("accepted"));

    const rejected = [
      event("story_choice", 1, "D2_A", { decision_id: "D2_A", choice_id: "A", behavior: "protectora", note: "texto libre" }),
    ];
    assert.equal((await ingest(rejected)).receipts[0].status, "invalid_event");
    sequence -= 1;
    assert.equal((await ingest([event("hint_request", 1, "D1", { level: "solucion" })])).receipts[0].status, "invalid_event");
    sequence -= 1;
    assert.equal((await ingest([event("session_start", 1, "coral", { platform: "web", build: "x", resumed: "si" })])).receipts[0].status, "invalid_event");
    sequence -= 1;

    // Una partida MOBA por día: D1 se acepta, repetir D1 no.
    assert.equal((await ingest([event("moba_result", 1, "moba", { result: "defeat" })])).receipts[0].status, "accepted");
    assert.equal((await ingest([event("moba_result", 1, "moba", { result: "draw" })])).receipts[0].status, "result_conflict");
    sequence -= 1;

    const ending = event("ending_reached", 4, "F01", { ending: "F01", profile: "learning",
      protective_choices: 5, limit_choices: 1, risk_choices: 1 });
    assert.equal((await ingest([ending])).receipts[0].status, "accepted");
    assert.equal((await ingest([event("ending_reached", 4, "F02", { ending: "F02", profile: "risk",
      protective_choices: 0, limit_choices: 0, risk_choices: 7 })])).receipts[0].status, "result_conflict");
    sequence -= 1;

    const finalized = await call(db, "centinela_finalize_sync", [owner, save.save_id, sequence]);
    assert.equal(finalized.sync_completed, true);

    const summary = (await db.query("select * from centinela_private.telemetry_summary where save_id = $1", [save.save_id])).rows[0];
    assert.equal(summary.sessions, 1);
    assert.equal(summary.last_day_started, 1);
    assert.equal(summary.choices, 1);
    assert.equal(summary.risk_choices, 1);
    assert.equal(summary.hints, 1);
    assert.equal(summary.pauses, 1);
    assert.equal(summary.inactive_seconds, 95);
    assert.equal(summary.moba_matches, 2);
    assert.equal(summary.ending, "F01");
    assert.equal(summary.telemetry_complete, true);
    const scores = await db.query("select count(*)::int as n from centinela_private.educational_scores where save_id = $1", [save.save_id]);
    assert.equal(scores.rows[0].n, 0, "la versión descriptiva no calcula puntajes");
    const rejections = await db.query("select count(*)::int as n from centinela_private.ingest_rejections where save_id = $1", [save.save_id]);
    assert.ok(rejections.rows[0].n >= 4);
  } finally {
    await db.close();
  }
});
