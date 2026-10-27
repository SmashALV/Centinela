import { datasetRows, toCsv, toXlsx } from "./export.mjs";

const notice = document.querySelector("#notice");
const authSection = document.querySelector("#auth");
const workspace = document.querySelector("#workspace");
const overview = document.querySelector("#overview");
const detail = document.querySelector("#detail");
const logout = document.querySelector("#logout");
let config;
let accessToken = "";
let selectedSession = "";

function message(text, kind = "") {
  notice.textContent = text;
  notice.className = `notice ${kind}`;
}
function node(tag, className = "", text = "") {
  const element = document.createElement(tag);
  if (className) element.className = className;
  element.textContent = text;
  return element;
}
function button(text, callback, className = "") {
  const element = node("button", className, text);
  element.type = "button";
  element.addEventListener("click", callback);
  return element;
}
function card(title) {
  const element = node("section", "card");
  element.append(node("h3", "", title));
  return element;
}
function table(headers, rows) {
  const wrap = node("div", "table-wrap");
  const element = node("table");
  const thead = node("thead");
  const headerRow = node("tr");
  headers.forEach((header) => headerRow.append(node("th", "", header)));
  thead.append(headerRow);
  element.append(thead);
  const body = node("tbody");
  rows.forEach((cells) => {
    const row = node("tr");
    cells.forEach((cell) => {
      const td = node("td");
      if (cell instanceof Node) td.append(cell);
      else td.textContent = cell == null ? "" : String(cell);
      row.append(td);
    });
    body.append(row);
  });
  element.append(body);
  wrap.append(element);
  return wrap;
}
function lima(value) {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return new Intl.DateTimeFormat("es-PE", { timeZone: "America/Lima", dateStyle: "short",
    timeStyle: "short", hour12: false }).format(date);
}
function percentage(value) { return value == null ? "Sin cobertura" : `${value} %`; }
function tag(value) {
  const labels = { planned: "Planificada", in_progress: "En curso", closed: "Cerrada",
    validated: "Validada", unvalidated: "Sin validar", test: "Prueba" };
  return node("span", `tag ${value}`, labels[value] || value);
}

async function request(action, dataOrId) {
  const payload = { action };
  if (["overview", "session", "report"].includes(action)) {
    if (action !== "overview") payload.id = dataOrId;
  } else payload.data = dataOrId;
  const response = await fetch(`${config.url}/functions/v1/research_admin`, {
    method: "POST", cache: "no-store",
    headers: { "content-type": "application/json", apikey: config.public_key,
      authorization: `Bearer ${accessToken}` },
    body: JSON.stringify(payload)
  });
  const result = await response.json().catch(() => ({}));
  if (!response.ok) {
    if (response.status === 401) signOut();
    throw new Error(result.error || `HTTP ${response.status}`);
  }
  return result;
}
async function run(action, data, success) {
  try {
    const result = await request(action, data);
    message(success);
    await loadOverview();
    if (selectedSession) await openSession(selectedSession);
    return result;
  } catch (error) { message(error.message, "error"); return null; }
}
function signOut() {
  accessToken = "";
  selectedSession = "";
  workspace.hidden = true;
  logout.hidden = true;
  authSection.hidden = !config?.enabled;
  detail.replaceChildren();
}

async function login(event) {
  event.preventDefault();
  const form = event.currentTarget;
  const fields = new FormData(form);
  const email = String(fields.get("email") || "").trim();
  const password = String(fields.get("password") || "");
  try {
    const response = await fetch(`${config.url}/auth/v1/token?grant_type=password`, {
      method: "POST", cache: "no-store",
      headers: { "content-type": "application/json", apikey: config.public_key },
      body: JSON.stringify({ email, password })
    });
    const result = await response.json();
    if (!response.ok || typeof result.access_token !== "string")
      throw new Error("Credenciales inválidas o Auth no disponible");
    accessToken = result.access_token;
    form.querySelector("[name=password]").value = "";
    await loadOverview();
    authSection.hidden = true;
    workspace.hidden = false;
    logout.hidden = false;
    message("Acceso administrativo verificado.");
  } catch (error) {
    accessToken = "";
    message(error.message, "error");
  }
}

async function loadOverview() {
  const data = await request("overview");
  overview.replaceChildren();
  const sessions = data.sessions || [];
  if (sessions.length === 0) {
    overview.append(node("p", "muted", "Todavía no hay sesiones SES."));
    return;
  }
  overview.append(table(["Sesión", "Estado", "Ventana · Lima", "Asociadas", "Validadas", "Global medio", "Informe"],
    sessions.map((session) => [button(session.code, () => openSession(session.id), "small quiet"),
      tag(session.state), `${lima(session.starts_at)} – ${lima(session.ends_at)}`,
      session.associated, session.validated,
      `${percentage(session.avg_global_pct)} (${session.covered || 0}/${session.validated})`,
      session.latest_report ? `v${session.latest_report}` : "—"])));
}

function input(name, placeholder = "", required = true) {
  const element = node("input");
  element.name = name;
  element.placeholder = placeholder;
  element.required = required;
  return element;
}
function labeled(title, control) {
  const label = node("label", "", title);
  label.append(control);
  return label;
}
function formSubmit(form, action, payload, success) {
  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const result = await run(action, payload(new FormData(form)), success);
    if (result) form.reset();
  });
}

async function openSession(sessionId) {
  selectedSession = sessionId;
  try {
    const data = await request("session", sessionId);
    detail.replaceChildren();
    const session = data.session;
    const heading = node("div", "section-heading");
    const titles = node("div");
    titles.append(node("p", "eyebrow", "SESIÓN SELECCIONADA"), node("h2", "", session.code));
    heading.append(titles, tag(session.state));
    detail.append(heading);

    const summary = card("Estado y linaje");
    const stats = node("div", "stat-row");
    for (const [label, value] of [
      ["Partidas", data.members.length], ["Validadas", data.members.filter((item) => item.status === "validated").length],
      ["Informes", data.reports.length], ["Eventos tardíos", data.members.reduce((n, item) => n + Number(item.late_events || 0), 0)],
      ["Rechazos", data.members.reduce((n, item) => n + Number(item.rejected_count || 0), 0)]
    ]) {
      const block = node("div", "stat");
      block.append(node("strong", "", value), node("small", "", label));
      stats.append(block);
    }
    summary.append(stats, node("p", "fine", `Juego ${session.game_version} · Narrativa ${session.narrative_version} · Rúbrica ${session.rubric_version} · Ventana Lima: ${lima(session.starts_at)} – ${lima(session.ends_at)}`));
    const transitions = node("div", "inline");
    if (session.state === "planned") transitions.append(button("Iniciar sesión", () =>
      run("set_state", { session_id: sessionId, state: "in_progress" }, "Sesión iniciada.")));
    if (session.state === "in_progress") transitions.append(button("Cerrar sesión", () =>
      run("set_state", { session_id: sessionId, state: "closed" }, "Sesión cerrada.")));
    if (session.state === "closed") {
      const reopen = node("form", "inline");
      const reopenReason = input("reason", "Mínimo 10 caracteres");
      reopenReason.minLength = 10;
      reopen.append(labeled("Motivo de reapertura", reopenReason), node("button", "", "Reabrir"));
      formSubmit(reopen, "set_state", (fields) => ({ session_id: sessionId,
        state: "in_progress", reason: fields.get("reason") }), "Reapertura auditada.");
      transitions.append(reopen);
    }
    summary.append(transitions);
    detail.append(summary);

    const membership = card("Códigos CTN y elegibilidad");
    membership.append(node("p", "fine", "La asociación usa únicamente el código seudónimo. Los informes incluyen solo partidas validadas. En los motivos, no escribas nombres ni datos personales."));
    if (session.state !== "closed") {
      const associate = node("form", "inline");
      const code = input("code", "CTN-000000");
      code.pattern = "CTN-[0-9]{6}";
      associate.append(labeled("Asociar CTN", code), node("button", "", "Asociar"));
      formSubmit(associate, "associate_save", (fields) => ({ session_id: sessionId,
        code: String(fields.get("code") || "").trim() }), "Partida asociada sin validar.");
      membership.append(associate);
    }
    membership.append(table(["Código", "Validación", "D1–D4 / global", "Sincronización", "Anomalías", "Acción"],
      data.members.map((member) => {
        const dimensions = (member.dimensions || []).map((item) =>
          `${item.dimension}: ${percentage(item.score_pct)} (${item.answered_items}/${item.required_items})`).join(" · ");
        const anomaly = [member.declared_sequence != null && member.last_sequence < member.declared_sequence ?
          `Faltan ${member.declared_sequence - member.last_sequence} eventos` : "",
          member.late_events ? `${member.late_events} tardío(s)` : "",
          member.rejected_count ? `${member.rejected_count} rechazo(s): ${(member.rejection_statuses || [])
            .map((item) => `${item.status} ${item.attempts}`).join(", ")}` : ""].filter(Boolean).join(" · ") || "—";
        const action = session.state === "closed" ? node("span", "muted", "Reabrir para cambiar") :
          button("Clasificar", () => showValidation(member, sessionId), "small quiet");
        return [member.code, tag(member.status), `${dimensions || "Sin rúbrica"} · Global: ${percentage(member.global_pct)}`,
          member.sync_completed ? "Completa" : "Pendiente", anomaly, action];
      })));
    detail.append(membership);

    const reports = card("Informes publicados");
    reports.append(node("p", "fine", "Cada versión conserva una instantánea. Los eventos recibidos después del cierre requieren inclusión explícita y justificación para una versión nueva."));
    const reportList = node("div", "report-list");
    data.reports.forEach((report) => reportList.append(button(`v${report.version} · ${lima(report.published_at)}`,
      () => openReport(report.id, reports), "small quiet")));
    reports.append(reportList);
    if (session.state === "closed") {
      const publish = node("form", "stack");
      const reason = input("reason", "Justificación de ausencias, partidas pendientes o eventos tardíos", false);
      const validated = data.members.filter((item) => item.status === "validated");
      const lateCount = validated.reduce((sum, item) => sum + Number(item.late_events || 0), 0);
      const hasIssues = validated.length === 0 || data.members.some((item) =>
        item.status !== "validated" || !item.story_completed || !item.sync_completed ||
        item.global_pct == null || Number(item.late_events || 0) > 0 ||
        Number(item.rejected_count || 0) > 0);
      reason.required = hasIssues;
      reason.minLength = hasIssues ? 10 : 0;
      const include = node("input");
      include.type = "checkbox";
      include.name = "include_late_events";
      include.required = lateCount > 0;
      const includeLabel = labeled("Incluir eventos tardíos revisados", include);
      if (hasIssues) publish.append(node("p", "alert-line",
        `Hay incidencias o métricas incompletas. Justifica la nueva versión.${lateCount > 0 ? ` Marca la inclusión explícita de ${lateCount} evento(s) tardío(s).` : ""}`));
      publish.append(labeled("Justificación del informe", reason), includeLabel,
        node("button", "", "Publicar versión nueva"));
      formSubmit(publish, "publish_report", (fields) => ({ session_id: sessionId,
        reason: String(fields.get("reason") || ""),
        include_late_events: fields.has("include_late_events") }), "Informe inmutable publicado.");
      reports.append(publish);
    }
    detail.append(reports);

    const audit = card("Auditoría");
    const list = node("ol", "audit-list");
    (data.audit || []).forEach((entry) => list.append(node("li", "",
      `${lima(entry.occurred_at)} · ${entry.action} · ${JSON.stringify(entry.detail || {})}`)));
    audit.append(list);
    detail.append(audit);
  } catch (error) { message(error.message, "error"); }
}

function showValidation(member, sessionId) {
  const existing = detail.querySelector("#validation-panel");
  if (existing) existing.remove();
  const panel = card(`Clasificar ${member.code}`);
  panel.id = "validation-panel";
  const form = node("form", "inline");
  const select = node("select");
  select.name = "status";
  for (const status of ["unvalidated", "validated", "test"]) {
    const option = node("option", "", status);
    option.value = status;
    select.append(option);
  }
  select.value = member.status;
  form.append(labeled("Estado", select), labeled("Motivo auditado", input("reason", "Mínimo 3 caracteres")),
    node("button", "", "Guardar clasificación"));
  form.querySelector("[name=reason]").minLength = 3;
  formSubmit(form, "validate_save", (fields) => ({ save_id: member.save_id,
    status: fields.get("status"), reason: fields.get("reason") }), "Clasificación guardada y auditada.");
  panel.append(form);
  detail.prepend(panel);
  panel.scrollIntoView({ behavior: "smooth", block: "start" });
}

function download(filename, content, mime) {
  const url = URL.createObjectURL(new Blob([content], { type: mime }));
  const anchor = node("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.append(anchor);
  anchor.click();
  anchor.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
async function openReport(reportId, parent) {
  try {
    const report = await request("report", reportId);
    parent.querySelector(".report-panel")?.remove();
    const panel = node("div", "report-panel");
    const snapshot = report.snapshot;
    panel.append(node("h3", "", `${snapshot.session_code} v${report.version}`),
      node("p", "fine", `Publicado: ${lima(report.published_at)} · Partidas validadas: ${snapshot.scores.length} · Decisiones: ${snapshot.decisions.length} · Eventos descriptivos: ${snapshot.descriptive.length} · Incidencias: ${snapshot.issue_count}`));
    if (snapshot.rubric_version.startsWith("TEST_ONLY_"))
      panel.append(node("p", "alert-line", "Rúbrica sintética de desarrollo: estas cifras no son resultados académicos."));
    const downloads = node("div", "download-row");
    for (const kind of ["scores", "decisions", "descriptive"]) {
      const dataset = datasetRows(snapshot, kind);
      const stem = `${snapshot.session_code}_v${report.version}_${kind}`;
      downloads.append(button(`${kind} · CSV`, () => download(`${stem}.csv`, toCsv(dataset),
        "text/csv;charset=utf-8"), "small quiet"));
      downloads.append(button(`${kind} · XLSX`, () => download(`${stem}.xlsx`, toXlsx(dataset, kind),
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"), "small quiet"));
    }
    panel.append(downloads);
    if (snapshot.decisions.length) {
      panel.append(node("h3", "", "Decisiones educativas"));
      panel.append(table(["CTN", "Decisión", "Opción", "Dimensión", "Puntos", "Recibido · Lima"],
        snapshot.decisions.slice(0, 50).map((item) => [item.code, item.decision_id,
          item.choice_id, item.dimension, item.awarded_points, lima(item.received_at)])));
    }
    if (snapshot.descriptive.length) {
      panel.append(node("h3", "", "Eventos descriptivos"));
      panel.append(table(["CTN", "Tipo", "Escena", "Dato", "Recibido · Lima"],
        snapshot.descriptive.slice(0, 50).map((item) => [item.code, item.kind,
          item.scene, item.result || item.mode || "—", lima(item.received_at)])));
    }
    if (snapshot.rejections?.length) {
      panel.append(node("h3", "", "Rechazos de sincronización"));
      panel.append(table(["CTN", "Motivo", "Intentos", "Último intento · Lima"],
        snapshot.rejections.map((item) => [item.code, item.status,
          item.attempts, lima(item.last_seen)])));
    }
    if (snapshot.decisions.length > 50 || snapshot.descriptive.length > 50)
      panel.append(node("p", "fine", "La vista muestra hasta 50 filas por tipo; la exportación conserva todas las filas del informe."));
    parent.append(panel);
  } catch (error) { message(error.message, "error"); }
}

document.querySelector("#login-form").addEventListener("submit", login);
document.querySelector("#refresh").addEventListener("click", () =>
  loadOverview().then(() => selectedSession && openSession(selectedSession)).catch((error) => message(error.message, "error")));
logout.addEventListener("click", () => { signOut(); message("Sesión cerrada en este navegador."); });
document.querySelector("#create-form").addEventListener("submit", async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const fields = new FormData(form);
  const result = await run("create_session", {
    code: String(fields.get("code") || "").trim(),
    starts_at: `${fields.get("starts_at")}:00-05:00`,
    ends_at: `${fields.get("ends_at")}:00-05:00`,
    game_version: String(fields.get("game_version") || "").trim(),
    narrative_version: String(fields.get("narrative_version") || "").trim(),
    rubric_version: String(fields.get("rubric_version") || "").trim()
  }, "Sesión creada.");
  if (result) { form.reset(); await openSession(result.session_id); }
});

try {
  const response = await fetch("./config.json", { cache: "no-store" });
  config = await response.json();
  const validUrl = typeof config.url === "string" && /^https?:\/\//.test(config.url);
  if (!config.enabled || !validUrl || typeof config.public_key !== "string") {
    message("Dashboard en espera: aplica la migración P6, despliega research_admin, configura la cuenta administrativa y activa dashboard/config.json.", "warn");
  } else {
    authSection.hidden = false;
    message("Ingresa con la cuenta administrativa aprobada.");
  }
} catch (_) { message("Falta dashboard/config.json.", "error"); }
