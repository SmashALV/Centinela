import assert from "node:assert/strict";
import { test } from "node:test";
import { datasetRows, toCsv, toXlsx } from "../dashboard/export.mjs";

function filesInStoredZip(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  const decoder = new TextDecoder();
  const files = new Map();
  let offset = 0;
  while (view.getUint32(offset, true) === 0x04034b50) {
    const length = view.getUint32(offset + 18, true);
    const nameLength = view.getUint16(offset + 26, true);
    const extraLength = view.getUint16(offset + 28, true);
    const name = decoder.decode(bytes.subarray(offset + 30, offset + 30 + nameLength));
    const start = offset + 30 + nameLength + extraLength;
    files.set(name, decoder.decode(bytes.subarray(start, start + length)));
    offset = start + length;
  }
  const end = bytes.length - 22;
  assert.equal(view.getUint32(end, true), 0x06054b50);
  const centralSize = view.getUint32(end + 12, true);
  const centralOffset = view.getUint32(end + 16, true);
  const centralCount = view.getUint16(end + 10, true);
  assert.equal(offset, centralOffset);
  assert.equal(centralCount, files.size);
  for (let i = 0; i < centralCount; i++) {
    assert.equal(view.getUint32(offset, true), 0x02014b50);
    offset += 46 + view.getUint16(offset + 28, true) +
      view.getUint16(offset + 30, true) + view.getUint16(offset + 32, true);
  }
  assert.equal(offset, centralOffset + centralSize);
  return files;
}

test("dashboard exporta datasets filtrados y XLSX válido sin fórmulas ni secretos", () => {
  const snapshot = { session_code: "SES-001", report_version: 2,
    scores: [{ code: "CTN-111111", save_id: "synthetic-uuid", narrative_version: "TEST_ONLY",
      rubric_version: "TEST_ONLY_RUBRIC", story_completed: true, sync_completed: true,
      last_sequence: 2, declared_sequence: 2, global_pct: null,
      dimensions: [{ dimension: "D1", answered_items: 1, required_items: 1, score_pct: 100 }] }],
    decisions: [{ code: "CTN-111111", event_id: "event-1", sequence: 1,
      decision_id: "TEST_ONLY_D1", choice_id: "TEST_ONLY_SAFE", dimension: "D1",
      awarded_points: 2, rubric_version: "TEST_ONLY_RUBRIC", received_at: "2026-10-27T15:00:00Z" }],
    descriptive: [{ code: "CTN-111111", event_id: "event-2", sequence: 2,
      kind: "moba_result", day: 0, scene: "moba", result: "draw" }],
    secret_hash: "SHOULD_NEVER_EXPORT", owner_auth_id: "SHOULD_NEVER_EXPORT" };
  for (const kind of ["scores", "decisions", "descriptive"]) {
    const table = datasetRows(snapshot, kind);
    assert.equal(table.rows.length, 1);
    const csv = toCsv(table);
    assert(csv.startsWith("\ufeff"));
    assert(!csv.includes("SHOULD_NEVER_EXPORT"));
    const files = filesInStoredZip(toXlsx(table, kind));
    assert(files.has("[Content_Types].xml"));
    assert(files.has("xl/workbook.xml"));
    assert(files.get("xl/worksheets/sheet1.xml").includes("CTN-111111"));
    assert(!files.get("xl/worksheets/sheet1.xml").includes("SHOULD_NEVER_EXPORT"));
  }
  assert.equal(toCsv({ headers: ["value"], rows: [["=HYPERLINK(\"x\")"]] }),
    '\ufeff"value"\r\n"\'=HYPERLINK(""x"")"\r\n');
});
