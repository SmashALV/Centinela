const assert = require("node:assert/strict");
const { createServer } = require("node:http");
const { readFile } = require("node:fs/promises");
const path = require("node:path");
const { chromium } = require("playwright-core");

const ROOT = path.resolve("build/web");
const MIME = { ".html": "text/html", ".js": "text/javascript", ".wasm": "application/wasm",
  ".pck": "application/octet-stream", ".png": "image/png" };

async function main() {
  const server = createServer(async (request, response) => {
    try {
      const pathname = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
      const file = path.resolve(ROOT, `.${pathname === "/" ? "/index.html" : pathname}`);
      if (!file.startsWith(ROOT + path.sep)) throw new Error("outside root");
      response.setHeader("Content-Type", MIME[path.extname(file)] || "application/octet-stream");
      response.end(await readFile(file));
    } catch (_) {
      response.writeHead(404);
      response.end("Not found");
    }
  });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const executablePath = process.env.CENTINELA_BROWSER_EXE ||
    "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
  const browser = await chromium.launch({
    executablePath,
    headless: true,
    args: ["--enable-webgl", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
  });
  try {
    const context = await browser.newContext({ viewport: { width: 1152, height: 672 } });
    const page = await context.newPage();
    const errors = [];
    const backendRequests = [];
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("console", (message) => { if (message.type() === "error") errors.push(message.text()); });
    page.on("request", (request) => {
      if (/\/auth\/v1\/|\/functions\/v1\//.test(request.url())) backendRequests.push(request.url());
    });
    await page.goto(`http://127.0.0.1:${server.address().port}/index.html`);
    await page.waitForFunction(() => !!globalThis.CentinelaStorage && !!globalThis.CentinelaSync,
      null, { timeout: 30000 });
    await page.waitForTimeout(1500);
    const canvas = await page.locator("canvas").boundingBox();
    assert(canvas, "Godot canvas missing");
    await page.screenshot({ path: "build/web/smoke.png" });
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    const readStore = async (storeName, key) => page.evaluate(async ({ storeName, key }) => {
      const db = await new Promise((resolve, reject) => {
        const request = indexedDB.open("centinela_2_local_v1");
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
      try {
        return await new Promise((resolve, reject) => {
          const request = db.transaction(storeName, "readonly").objectStore(storeName).get(key);
          request.onsuccess = () => resolve(request.result || null);
          request.onerror = () => reject(request.error);
        });
      } finally {
        db.close();
      }
    }, { storeName, key });
    const waitForStore = async (storeName, key, predicate, timeout = 15000) => {
      const deadline = Date.now() + timeout;
      while (Date.now() < deadline) {
        const value = await readStore(storeName, key);
        if (predicate(value)) return value;
        await page.waitForTimeout(100);
      }
      throw new Error(`Timed out waiting for ${storeName}:${key}`);
    };
    const initialDialogue = await waitForStore("save_snapshots", 1,
      (record) => record?.snapshot?.dialogue_key === "wakeup");
    await page.keyboard.press("Enter");
    const saved = await waitForStore("save_snapshots", 1,
      (record) => record?.snapshot?.dialogue_key === "wakeup" &&
        record.snapshot.dialogue_position > initialDialogue.snapshot.dialogue_position);
    assert.equal(saved.snapshot.slot, 1);
    assert.equal(saved.snapshot.phase, "bedroom");
    const firstLock = await readStore("locks", 1);
    assert(firstLock?.generation > 0, "slot lock missing");
    const competing = await context.newPage();
    competing.on("pageerror", (error) => errors.push(error.message));
    await competing.goto(`http://127.0.0.1:${server.address().port}/index.html`);
    await competing.waitForFunction(() => !!globalThis.CentinelaStorage);
    await competing.waitForTimeout(1000);
    await competing.evaluate(() => {
      globalThis.__lockResult = null;
      const original = globalThis.CentinelaStorage.request;
      globalThis.CentinelaStorage.request = (raw, callback) => original(raw, (response) => {
        if (JSON.parse(raw).operation === "acquire_lock") globalThis.__lockResult = JSON.parse(response);
        callback(response);
      });
    });
    await competing.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await competing.waitForFunction(() => !!globalThis.__lockResult, null, { timeout: 15000 });
    assert.equal((await competing.evaluate(() => globalThis.__lockResult)).error.code, "LOCK_HELD");
    await competing.close();
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1200);
    await page.screenshot({ path: "build/web/reloaded.png" });
    const persisted = await readStore("save_snapshots", 1);
    assert.deepEqual(persisted.snapshot, saved.snapshot);
    await page.evaluate(() => {
      globalThis.__storageRequests = [];
      const original = globalThis.CentinelaStorage.request;
      globalThis.CentinelaStorage.request = (raw, callback) => {
        const entry = { operation: JSON.parse(raw).operation };
        globalThis.__storageRequests.push(entry);
        return original(raw, (response) => {
          entry.response = JSON.parse(response);
          callback(response);
        });
      };
    });
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    const deadline = Date.now() + 15000;
    let loaded = null;
    while (Date.now() < deadline && !loaded) {
      loaded = await page.evaluate(() => globalThis.__storageRequests.find(
        (entry) => entry.operation === "load_slot" && entry.response));
      if (!loaded) await page.waitForTimeout(100);
    }
    assert(loaded?.response?.success, "slot was not reloaded");
    assert.deepEqual(loaded.response.result, saved.snapshot);
    const resumedLock = await readStore("locks", 1);
    assert.equal(resumedLock.generation, firstLock.generation);
    assert.equal(resumedLock.tab_id, firstLock.tab_id);
    await page.evaluate(async () => {
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
            record.snapshot.dialogue_key = "";
            record.snapshot.dialogue_position = 0;
            record.snapshot.dialogue_choice = "";
            record.snapshot.flags.wakeup_seen = true;
            record.snapshot.ui_modal = "phone";
            record.snapshot.hint_level = 1;
            store.put(record);
          };
          transaction.oncomplete = resolve;
          transaction.onerror = () => reject(transaction.error);
        });
      } finally { db.close(); }
    });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1000);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.screenshot({ path: "build/web/reloaded_phone.png" });
    await page.keyboard.press("Escape");
    const closedPhone = await waitForStore("save_snapshots", 1,
      (record) => record?.snapshot?.ui_modal === "");
    assert.equal(closedPhone.snapshot.hint_level, 1);
    await page.evaluate(async () => {
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
            record.snapshot.phase = "preview";
            record.snapshot.preview_scene = "D2_03_A";
            record.snapshot.preview_step = 2;
            record.snapshot.preview_choices = {};
            record.snapshot.dialogue_key = "";
            record.snapshot.dialogue_position = 0;
            record.snapshot.dialogue_choice = "";
            store.put(record);
          };
          transaction.oncomplete = resolve;
          transaction.onerror = () => reject(transaction.error);
        });
      } finally {
        db.close();
      }
    });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1000);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(800);
    await page.screenshot({ path: "build/web/preview_d2.png" });
    const previewSave = await readStore("save_snapshots", 1);
    assert.equal(previewSave.snapshot.preview_scene, "D2_03_A");
    assert.equal(previewSave.snapshot.preview_step, 2);
    await page.evaluate(async () => {
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
            record.snapshot.preview_step = 9;
            record.snapshot.text_size = "large";
            store.put(record);
          };
          transaction.oncomplete = resolve;
          transaction.onerror = () => reject(transaction.error);
        });
      } finally { db.close(); }
    });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1000);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(600);
    await page.screenshot({ path: "build/web/preview_choices_large.png" });
    await page.keyboard.press("2");
    const selected = await waitForStore("save_snapshots", 1, (record) =>
      record?.snapshot?.preview_choices?.D2_03_A === "B");
    assert.equal(selected.snapshot.preview_step, 10);
    await page.evaluate(async () => {
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
            record.snapshot.preview_step = 9;
            record.snapshot.preview_choices = {};
            store.put(record);
          };
          transaction.oncomplete = resolve;
          transaction.onerror = () => reject(transaction.error);
        });
      } finally { db.close(); }
    });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1000);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    const arrowSelected = await waitForStore("save_snapshots", 1, (record) =>
      record?.snapshot?.preview_choices?.D2_03_A === "B");
    assert.equal(arrowSelected.snapshot.preview_step, 10);
    await page.setViewportSize({ width: 600, height: 360 });
    await page.waitForTimeout(800);
    await page.screenshot({ path: "build/web/window_too_small.png" });
    await page.setViewportSize({ width: 1152, height: 672 });
    await page.waitForTimeout(600);
    await page.screenshot({ path: "build/web/window_restored_pause.png" });
    await page.setViewportSize({ width: 768, height: 448 });
    await page.waitForTimeout(600);
    await page.screenshot({ path: "build/web/window_minimum.png" });
    console.log("Canvas:", canvas);
    console.log("Browser:", path.basename(executablePath));
    console.log("Persisted slot:", { slot: saved.snapshot.slot, phase: saved.snapshot.phase });
    console.log("Browser errors:", errors);
    assert.equal(errors.length, 0, errors.join("\n"));
    assert.equal(backendRequests.length, 0, "unconfigured backend must stay offline");
  } finally {
    await browser.close();
    await new Promise((resolve) => server.close(resolve));
  }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
