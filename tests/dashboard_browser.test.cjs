const assert = require("node:assert/strict");
const { createServer } = require("node:http");
const { readFile } = require("node:fs/promises");
const path = require("node:path");
const { chromium } = require("playwright-core");

const ROOT = path.resolve("dashboard");
const ID = "11111111-1111-4111-8111-111111111111";
const REPORT_ID = "22222222-2222-4222-8222-222222222222";
const session = { id: ID, code: "SES-001", state: "closed",
  starts_at: "2026-10-27T14:00:00Z", ends_at: "2026-10-27T17:00:00Z",
  closed_at: "2026-10-27T17:00:00Z", game_version: "TEST_ONLY_P6",
  narrative_version: "provisional-d0-1", rubric_version: "TEST_ONLY_P4_v1" };
const snapshot = { schema_version: 1, session_code: "SES-001", report_version: 1,
  rubric_version: "TEST_ONLY_P4_v1", issue_count: 0, scores: [{ code: "CTN-111111",
    save_id: "synthetic-save", narrative_version: "provisional-d0-1",
    rubric_version: "TEST_ONLY_P4_v1", story_completed: true, sync_completed: true,
    last_sequence: 1, declared_sequence: 1, global_pct: null,
    dimensions: [{ dimension: "D1", answered_items: 1, required_items: 1, score_pct: 100 }] }],
  decisions: [], descriptive: [] };

async function main() {
  const server = createServer(async (request, response) => {
    try {
      const pathname = new URL(request.url, "http://localhost").pathname;
      const file = path.resolve(ROOT, `.${pathname === "/" ? "/index.html" : pathname}`);
      if (!file.startsWith(ROOT + path.sep)) throw new Error("outside root");
      response.setHeader("Content-Type", file.endsWith(".mjs") ? "text/javascript" :
        file.endsWith(".css") ? "text/css" : file.endsWith(".json") ? "application/json" : "text/html");
      response.end(await readFile(file));
    } catch (_) { response.writeHead(404); response.end("Not found"); }
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const browser = await chromium.launch({
    executablePath: "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    headless: true
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1380, height: 900 }, acceptDownloads: true });
    const errors = [];
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("console", (entry) => { if (entry.type() === "error") errors.push(entry.text()); });
    await page.route("**/config.json", (route) => route.fulfill({ status: 200,
      contentType: "application/json", body: JSON.stringify({ enabled: true,
        url: "https://mock.supabase.co", public_key: "TEST_ONLY_PUBLIC" }) }));
    await page.route("https://mock.supabase.co/**", async (route) => {
      const request = route.request();
      if (request.url().includes("/auth/v1/token")) {
        await route.fulfill({ status: 200, contentType: "application/json",
          body: JSON.stringify({ access_token: "TEST_ONLY_JWT" }) });
        return;
      }
      assert.equal(request.headers().authorization, "Bearer TEST_ONLY_JWT");
      const { action } = request.postDataJSON();
      const body = action === "overview" ? { sessions: [{ ...session, associated: 1,
        validated: 1, latest_report: 1 }] } :
        action === "session" ? { session, members: [{ save_id: "synthetic-save",
          code: "CTN-111111", status: "validated", reason: "Verificado",
          story_completed: true, sync_completed: true, last_sequence: 1,
          declared_sequence: 1, global_pct: null, late_events: 0,
          dimensions: snapshot.scores[0].dimensions }],
          reports: [{ id: REPORT_ID, version: 1, published_at: "2026-10-27T18:00:00Z" }],
          audit: [] } : action === "report" ? { id: REPORT_ID, version: 1,
          published_at: "2026-10-27T18:00:00Z", snapshot } : {};
      await route.fulfill({ status: 200, contentType: "application/json", body: JSON.stringify(body) });
    });
    await page.goto(`http://127.0.0.1:${server.address().port}/index.html`);
    await page.getByLabel("Correo electrónico").fill("admin@example.test");
    await page.getByLabel("Contraseña").fill("synthetic-password");
    await page.getByRole("button", { name: "Ingresar" }).click();
    await page.getByRole("button", { name: "SES-001" }).click();
    await page.getByRole("button", { name: /v1 ·/ }).click();
    assert(await page.getByText("Rúbrica sintética de desarrollo", { exact: false }).isVisible());
    const downloadPromise = page.waitForEvent("download");
    await page.getByRole("button", { name: "scores · XLSX" }).click();
    const download = await downloadPromise;
    assert.equal(download.suggestedFilename(), "SES-001_v1_scores.xlsx");
    await page.screenshot({ path: "build/dashboard_preview.png", fullPage: true });
    assert.equal(await page.evaluate(() => localStorage.length), 0);
    assert.equal(errors.length, 0, errors.join("\n"));
    console.log("Dashboard browser: login, session, report and XLSX download OK");
  } finally {
    await browser.close();
    await new Promise((resolve) => server.close(resolve));
  }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
