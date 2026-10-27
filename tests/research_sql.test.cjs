const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const { randomUUID } = require("node:crypto");
const { test } = require("node:test");
const { PGlite } = require("@electric-sql/pglite");

const p4 = readFileSync("supabase/migrations/20261027000100_p4_core.sql", "utf8");
const p6 = readFileSync("supabase/migrations/20261027000200_p6_research.sql", "utf8");
const seed = readFileSync("supabase/seed.sql", "utf8");

async function call(db, functionName, args) {
  const placeholders = args.map((_, index) => `$${index + 1}`).join(", ");
  const result = await db.query(`select public.${functionName}(${placeholders}) as value`, args);
  return result.rows[0].value;
}

test("P6 SQL: permisos, validación manual, informes inmutables y eventos tardíos", async () => {
  const db = new PGlite();
  try {
    await db.exec("create role anon; create role authenticated; create role service_role; create schema auth; create table auth.users(id uuid primary key);");
    await db.exec(p4);
    await db.exec(p6);
    await db.exec(seed);
    const admin = randomUUID();
    const stranger = randomUUID();
    const owner = randomUUID();
    await db.query("insert into auth.users(id) values ($1), ($2), ($3)", [admin, stranger, owner]);
    await db.query("insert into centinela_private.research_admins(auth_id) values ($1)", [admin]);
    assert.equal(await call(db, "centinela_research_is_admin", [admin]), true);
    assert.equal(await call(db, "centinela_research_is_admin", [stranger]), false);
    await assert.rejects(() => call(db, "centinela_research_read", [stranger, "overview", null]));

    const command = (actor, action, data) => call(db, "centinela_research_command",
      [actor, action, JSON.stringify(data)]);
    const read = (action, id = null) => call(db, "centinela_research_read", [admin, action, id]);
    const session = await command(admin, "create_session", {
      code: "SES-001", starts_at: "2026-10-27T09:00:00-05:00",
      ends_at: "2026-10-27T12:00:00-05:00", game_version: "TEST_ONLY_P6",
      narrative_version: "provisional-d0-1", rubric_version: "TEST_ONLY_P4_v1"
    });
    assert.equal(session.code, "SES-001");
    await assert.rejects(() => command(stranger, "create_session", {
      code: "SES-002", starts_at: "2026-10-27T09:00:00-05:00",
      ends_at: "2026-10-27T12:00:00-05:00", game_version: "TEST_ONLY_P6",
      narrative_version: "provisional-d0-1", rubric_version: "TEST_ONLY_P4_v1"
    }));
    assert.equal((await read("overview")).sessions.length, 1);
    await command(admin, "set_state", { session_id: session.session_id, state: "in_progress" });

    async function register(code) {
      return call(db, "centinela_register_save", [owner, randomUUID(), code,
        "provisional-d0-1", "TEST_ONLY_P4_v1", "a".repeat(64), true]);
    }
    const primary = await register("CTN-111111");
    const excludedTest = await register("CTN-222222");
    const excludedPending = await register("CTN-333333");
    for (const save of [primary, excludedTest, excludedPending]) {
      await command(admin, "associate_save", { session_id: session.session_id, code: save.code });
    }
    await command(admin, "validate_save", { save_id: primary.save_id,
      status: "validated", reason: "Código verificado en planilla seudónima" });
    await command(admin, "validate_save", { save_id: excludedTest.save_id,
      status: "test", reason: "Partida de prueba del equipo" });
    const detail = await read("session", session.session_id);
    assert.deepEqual(detail.members.map((member) => member.status).sort(),
      ["test", "unvalidated", "validated"]);
    assert.equal(detail.members.find((member) => member.code === primary.code).global_pct, null);
    await assert.rejects(() => command(admin, "validate_save", { save_id: primary.save_id,
      status: "validated", reason: "" }));

    const event = { event_id: randomUUID(), sequence: 1, kind: "decision",
      narrative_version: "provisional-d0-1", rubric_version: "TEST_ONLY_P4_v1",
      day: 1, scene: "TEST_ONLY_SCENE", occurred_at: "2026-10-27T15:00:00Z",
      context: {}, decision_id: "TEST_ONLY_D1", choice_id: "TEST_ONLY_SAFE" };
    const gap = { ...event, event_id: randomUUID(), sequence: 3 };
    const receipt = await call(db, "centinela_ingest_events_with_audit", [owner, primary.save_id,
      JSON.stringify([gap, event])]);
    assert.deepEqual(receipt.receipts.map((item) => item.status),
      ["missing_sequence", "accepted"]);
    const invalid = { ...event, event_id: randomUUID(), sequence: 2,
      student_name: "TEST_ONLY_NAME" };
    assert.equal((await call(db, "centinela_ingest_events_with_audit", [owner,
      primary.save_id, JSON.stringify([invalid])])).receipts[0].status, "invalid_event");
    const rejectionRows = await db.query("select * from centinela_private.ingest_rejections where save_id=$1", [primary.save_id]);
    assert.equal(rejectionRows.rows.length, 2);
    assert(!JSON.stringify(rejectionRows.rows).includes("TEST_ONLY_NAME"));
    await call(db, "centinela_finalize_sync", [owner, primary.save_id, 2]);
    await command(admin, "set_state", { session_id: session.session_id, state: "closed" });
    await assert.rejects(() => command(admin, "validate_save", { save_id: primary.save_id,
      status: "test", reason: "Cambio tardío" }));
    await assert.rejects(() => command(admin, "publish_report", { session_id: session.session_id }));
    const first = await command(admin, "publish_report", { session_id: session.session_id,
      reason: "Incluye una partida pendiente de sincronización" });
    assert.equal(first.version, 1);
    const firstReport = await read("report", first.report_id);
    assert.equal(firstReport.snapshot.scores.length, 1);
    assert.equal(firstReport.snapshot.scores[0].code, primary.code);
    assert.equal(firstReport.snapshot.decisions.length, 1);
    assert.equal(firstReport.snapshot.descriptive.length, 0);
    assert.equal(firstReport.snapshot.rejections.length, 2);
    assert.equal(firstReport.snapshot.scores[0].dimensions[0].score_pct, 100);
    assert(!JSON.stringify(firstReport).includes("secret_hash"));
    assert(!JSON.stringify(firstReport).includes("owner_auth_id"));
    await assert.rejects(() => db.query("update centinela_private.published_reports set version=9 where id=$1", [first.report_id]));
    await assert.rejects(() => db.query("delete from centinela_private.research_audit where session_id=$1", [session.session_id]));

    const late = { ...event, event_id: randomUUID(), sequence: 2,
      kind: "moba_result", context: { result: "draw" } };
    delete late.decision_id;
    delete late.choice_id;
    assert.equal((await call(db, "centinela_ingest_events_with_audit", [owner, primary.save_id,
      JSON.stringify([late])])).receipts[0].status, "accepted");
    assert.equal((await read("session", session.session_id)).members
      .find((member) => member.code === primary.code).late_events, 1);
    await assert.rejects(() => command(admin, "publish_report", {
      session_id: session.session_id, reason: "Se registró un evento tardío"
    }));
    const second = await command(admin, "publish_report", { session_id: session.session_id,
      include_late_events: true, reason: "Se revisó y aprobó el evento tardío recibido" });
    assert.equal(second.version, 2);
    const secondReport = await read("report", second.report_id);
    assert.equal(secondReport.snapshot.descriptive.length, 1);
    assert.equal(secondReport.snapshot.late_event_count, 1);
    assert.equal((await read("report", first.report_id)).snapshot.descriptive.length, 0);
    await assert.rejects(() => command(admin, "set_state", {
      session_id: session.session_id, state: "in_progress", reason: "breve"
    }));
    await command(admin, "set_state", { session_id: session.session_id,
      state: "in_progress", reason: "Corrección documentada de validación" });
    assert((await read("session", session.session_id)).audit
      .some((entry) => entry.action === "reopen_session"));

    await db.exec("set role anon");
    await assert.rejects(() => db.query("select public.centinela_research_read($1,'overview',null)", [admin]));
    await assert.rejects(() => db.query("select public.centinela_ingest_events_with_audit($1,$2,'[]'::jsonb)", [owner, primary.save_id]));
    await db.exec("reset role");
  } finally {
    await db.close();
  }
});
