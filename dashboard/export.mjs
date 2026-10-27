const DIMENSIONS = ["D1", "D2", "D3", "D4"];

function cleanText(value) {
  if (value == null) return "";
  return String(value);
}

export function datasetRows(snapshot, kind) {
  const base = ["session_code", "report_version"];
  if (kind === "scores") {
    const headers = [...base, "code", "save_id", "narrative_version", "rubric_version",
      "story_completed", "sync_completed", "last_sequence", "declared_sequence", "rejected_count",
      ...DIMENSIONS.flatMap((dimension) => [`${dimension}_answered`, `${dimension}_required`, `${dimension}_pct`]),
      "global_pct"];
    const rows = (snapshot.scores || []).map((save) => {
      const dimensions = new Map((save.dimensions || []).map((item) => [item.dimension, item]));
      return [snapshot.session_code, snapshot.report_version, save.code, save.save_id,
        save.narrative_version, save.rubric_version, save.story_completed, save.sync_completed,
        save.last_sequence, save.declared_sequence, save.rejected_count,
        ...DIMENSIONS.flatMap((dimension) => {
          const value = dimensions.get(dimension) || {};
          return [value.answered_items, value.required_items, value.score_pct];
        }), save.global_pct];
    });
    return { headers, rows };
  }
  if (kind === "decisions") {
    const fields = ["code", "event_id", "sequence", "decision_id", "choice_id", "dimension",
      "awarded_points", "rubric_version", "received_at"];
    return { headers: [...base, ...fields], rows: (snapshot.decisions || []).map((item) =>
      [snapshot.session_code, snapshot.report_version, ...fields.map((field) => item[field])]) };
  }
  if (kind === "descriptive") {
    const fields = ["code", "event_id", "sequence", "kind", "day", "scene", "occurred_at",
      "received_at", "result", "mode", "duration_s"];
    return { headers: [...base, ...fields], rows: (snapshot.descriptive || []).map((item) =>
      [snapshot.session_code, snapshot.report_version, ...fields.map((field) => item[field])]) };
  }
  throw new Error("Unknown dataset");
}

export function toCsv(table) {
  const quote = (value) => {
    let text = cleanText(value);
    if (typeof value === "string" && /^[\s]*[=+\-@]/.test(text)) text = "'" + text;
    return `"${text.replaceAll('"', '""')}"`;
  };
  return "\ufeff" + [table.headers, ...table.rows].map((row) => row.map(quote).join(",")).join("\r\n") + "\r\n";
}

function xml(value) {
  return cleanText(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&apos;");
}

function column(index) {
  let label = "";
  for (let n = index + 1; n > 0; n = Math.floor((n - 1) / 26))
    label = String.fromCharCode(65 + ((n - 1) % 26)) + label;
  return label;
}

function sheetXml(table) {
  const rows = [table.headers, ...table.rows];
  const body = rows.map((row, rowIndex) => `<row r="${rowIndex + 1}">` +
    row.map((value, colIndex) => {
      const ref = `${column(colIndex)}${rowIndex + 1}`;
      if (typeof value === "number" && Number.isFinite(value))
        return `<c r="${ref}"><v>${value}</v></c>`;
      return `<c r="${ref}" t="inlineStr"><is><t xml:space="preserve">${xml(value)}</t></is></c>`;
    }).join("") + "</row>").join("");
  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>` +
    `<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>${body}</sheetData></worksheet>`;
}

const encoder = new TextEncoder();
function u16(value) { return [value & 255, (value >>> 8) & 255]; }
function u32(value) { return [...u16(value), ...u16(value >>> 16)]; }
function concat(chunks) {
  const total = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
  const output = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) { output.set(chunk, offset); offset += chunk.length; }
  return output;
}
function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let i = 0; i < 8; i++) crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
  }
  return (crc ^ 0xffffffff) >>> 0;
}
function zip(files) {
  const local = [];
  const central = [];
  let offset = 0;
  for (const [name, content] of files) {
    const filename = encoder.encode(name);
    const bytes = encoder.encode(content);
    const crc = crc32(bytes);
    const common = [...u16(20), ...u16(0x0800), ...u16(0), ...u16(0), ...u16(0),
      ...u32(crc), ...u32(bytes.length), ...u32(bytes.length), ...u16(filename.length)];
    const localHeader = Uint8Array.from([...u32(0x04034b50), ...common, ...u16(0), ...filename]);
    local.push(localHeader, bytes);
    central.push(Uint8Array.from([...u32(0x02014b50), ...u16(20), ...common,
      ...u16(0), ...u16(0), ...u16(0), ...u16(0), ...u32(0), ...u32(offset), ...filename]));
    offset += localHeader.length + bytes.length;
  }
  const centralBytes = concat(central);
  return concat([...local, centralBytes, Uint8Array.from([
    ...u32(0x06054b50), ...u16(0), ...u16(0), ...u16(files.length), ...u16(files.length),
    ...u32(centralBytes.length), ...u32(offset), ...u16(0)
  ])]);
}

export function toXlsx(table, sheetName = "Datos") {
  const safeName = cleanText(sheetName).replace(/[\[\]:*?/\\]/g, "_").slice(0, 31) || "Datos";
  return zip([
    ["[Content_Types].xml", `<?xml version="1.0" encoding="UTF-8"?>` +
      `<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">` +
      `<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>` +
      `<Default Extension="xml" ContentType="application/xml"/>` +
      `<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>` +
      `<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>` +
      `</Types>`],
    ["_rels/.rels", `<?xml version="1.0" encoding="UTF-8"?>` +
      `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` +
      `<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>` +
      `</Relationships>`],
    ["xl/workbook.xml", `<?xml version="1.0" encoding="UTF-8"?>` +
      `<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" ` +
      `xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">` +
      `<sheets><sheet name="${xml(safeName)}" sheetId="1" r:id="rId1"/></sheets></workbook>`],
    ["xl/_rels/workbook.xml.rels", `<?xml version="1.0" encoding="UTF-8"?>` +
      `<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">` +
      `<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>` +
      `</Relationships>`],
    ["xl/worksheets/sheet1.xml", sheetXml(table)]
  ]);
}
