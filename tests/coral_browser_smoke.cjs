const assert = require("node:assert/strict");
const { createServer } = require("node:http");
const { readFile } = require("node:fs/promises");
const path = require("node:path");
const { chromium } = require("playwright-core");

const root = path.resolve("build/web");
const mime = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png" };

async function main() {
  const server = createServer(async (request, response) => {
    try {
      const pathname = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
      const file = path.resolve(root, `.${pathname === "/" ? "/index.html" : pathname}`);
      if (!file.startsWith(root + path.sep)) throw new Error("outside root");
      response.setHeader("Content-Type", mime[path.extname(file)] || "application/octet-stream");
      response.end(await readFile(file));
    } catch (_) { response.writeHead(404); response.end("Not found"); }
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const browser = await chromium.launch({
    executablePath: process.env.CENTINELA_BROWSER_EXE ||
      "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    headless: true, args: ["--enable-webgl", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1152, height: 672 } });
    const errors = [];
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()); });
    const url = `http://127.0.0.1:${server.address().port}/index.html`;
    await page.goto(url);
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1000);
    const canvas = await page.locator("canvas").boundingBox();
    assert(canvas);
    const readSave = () => page.evaluate(async () => {
      const db = await new Promise((resolve, reject) => {
        const request = indexedDB.open("centinela_2_local_v1");
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      try {
        return await new Promise((resolve, reject) => {
          const request = db.transaction("save_snapshots").objectStore("save_snapshots").get(1);
          request.onsuccess = () => resolve(request.result?.snapshot || null);
          request.onerror = () => reject(request.error);
        });
      } finally { db.close(); }
    });
    const waitFor = async (predicate) => {
      const until = Date.now() + 45000;
      while (Date.now() < until) {
        const state = await readSave();
        if (predicate(state)) {
          await page.waitForTimeout(250);
          return state;
        }
        await page.waitForTimeout(120);
      }
      throw new Error("Timed out waiting for coral state");
    };
    await page.evaluate(async () => {
      const send = (operation, payload) => new Promise((resolve, reject) => {
        CentinelaStorage.request(JSON.stringify({ protocol_version: 1, request_id: crypto.randomUUID(),
          operation, payload }), (raw) => {
          const result = JSON.parse(raw);
          if (result.success) resolve(result.result);
          else reject(new Error(result.error?.code || "STORAGE_ERROR"));
        });
      });
      const lock = await send("acquire_lock", { slot: 1 });
      await send("save_snapshot", { slot: 1, generation: lock.generation,
        snapshot: { schema_version: 1, narrative_version: "provisional-d0-1", slot: 1,
          code: "CTN-000001", phase: "result", flags: {}, player_position: [384, 320],
          phone_messages: [], moba_class: "Defensor", moba_result: "victoria" } });
      await send("release_lock", { slot: 1, generation: lock.generation });
    });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(900);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await waitFor((state) => state?.flags?.d1_interlude_active === true);
    await waitFor((state) => state?.phase === "coral" && state.coral_state?.mode === "intro");
    await page.screenshot({ path: "build/web/coral_intro.png" });
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.76);
    await waitFor((state) => state?.coral_state?.step === 1);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: "build/web/dialogue_timer_before_pause.png" });
    await page.keyboard.press("p");
    await page.waitForTimeout(500);
    assert.equal((await readSave()).coral_state.step, 1);
    await page.keyboard.press("p");
    await page.waitForTimeout(200);
    await page.screenshot({ path: "build/web/dialogue_timer_resumed.png" });
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.76);
    await waitFor((state) => state?.coral_state?.mode === "explore");
    await page.screenshot({ path: "build/web/coral_explore.png" });
    const inject = async (change) => page.evaluate(async (change) => {
      const db = await new Promise((resolve, reject) => {
        const request = indexedDB.open("centinela_2_local_v1");
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      try {
        await new Promise((resolve, reject) => {
          const transaction = db.transaction("save_snapshots", "readwrite");
          const store = transaction.objectStore("save_snapshots");
          const request = store.get(1);
          request.onsuccess = () => {
            const record = request.result;
            Object.assign(record.snapshot, change.snapshotChanges || {});
            const { snapshotChanges, ...storyChanges } = change;
            Object.assign(record.snapshot.coral_state, storyChanges);
            store.put(record);
          };
          transaction.oncomplete = resolve;
          transaction.onerror = () => reject(transaction.error);
        });
      } finally { db.close(); }
    }, change);
    await inject({ day: 1, mode: "scene", node: "I_D1_CAMILA", step: 0 });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/dialogue_computer_lab.png" });
    await inject({ day: 1, mode: "scene", node: "D1_GATE", step: 14,
      snapshotChanges: { text_size: "large" } });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/dialogue_group_long.png" });
    await inject({ day: 1, mode: "scene", node: "D1_B_FOLLOW", step: 8 });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/dialogue_dm_long.png" });
    await inject({ day: 1, mode: "scene", node: "D1_B_FOLLOW", step: 0, route: "B",
      choices: { D1_GATE: "B" }, snapshotChanges: { text_size: "normal" } });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/coral_mateo_dm.png" });
    await inject({ day: 4, mode: "scene", node: "D4_B1", step: 1, route: "B", branch: "B1",
      choices: { D1_GATE: "B", D2_B: "A" } });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/coral_day4_vn.png" });
    await inject({ day: 2, mode: "scene", node: "D2_A", step: 0 });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/camila_identity_v2.png" });
    await inject({ day: 4, mode: "ending", node: "F01", step: 6, ending: "F01", adult_support_started: true,
      choices: { D2_A: "A", D2_B: "B", D2_C: "A" } });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/closing_education.png" });
    await inject({ snapshotChanges: { phase: "bedroom", flags: {}, coral_state: {},
      dialogue_key: "", dialogue_position: 0, dialogue_choice: "", dialogue_history: [], ui_modal: "" } });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/prologue_full_pastel.png" });
    await page.keyboard.press("Enter");
    await waitFor((state) => state?.dialogue_key === "wakeup");
    for (let i = 0; i < 5; i++) {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(350);
      if ((await readSave())?.flags?.wakeup_seen) break;
    }
    await waitFor((state) => state?.flags?.wakeup_seen === true);
    assert.equal((await readSave()).flags.d0_guide_active, "bedroom");
    await page.screenshot({ path: "build/web/bedroom_guide.png" });
    await page.keyboard.press("Enter");
    await waitFor((state) => state?.flags?.d0_guide_bedroom_seen === true);
    await page.screenshot({ path: "build/web/bedroom_decorated.png" });
    assert.deepEqual(errors, []);
    console.log("PASS Web: D0→D1, exploración, privado de Mateo y novela visual D4");
    await page.close();
  } finally { await browser.close(); await new Promise((resolve) => server.close(resolve)); }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
