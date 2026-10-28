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
    await waitForStore("save_snapshots", 1,
      (record) => record?.snapshot?.phase === "bedroom" &&
        !record.snapshot.flags.prologue_seen && !record.snapshot.dialogue_key);
    await page.waitForTimeout(300);
    await page.screenshot({ path: "build/web/prologue.png" });
    for (const step of [1, 2]) {
      await page.keyboard.press("Enter");
      await waitForStore("save_snapshots", 1,
        (record) => record?.snapshot?.flags?.prologue_step === step);
      if (step === 1) await page.screenshot({ path: "build/web/prologue_sofi.png" });
    }
    await page.keyboard.press("Enter");
    const initialDialogue = await waitForStore("save_snapshots", 1,
      (record) => record?.snapshot?.flags?.prologue_seen === true &&
        record.snapshot.dialogue_key === "wakeup");
    await page.waitForTimeout(300);
    await page.screenshot({ path: "build/web/dialogue_portrait.png" });
    let saved = null;
    for (let attempt = 0; attempt < 3 && !saved; attempt++) {
      await page.keyboard.press("Enter");
      await page.waitForTimeout(250);
      const current = await readStore("save_snapshots", 1);
      if (current?.snapshot?.dialogue_key === "wakeup" &&
          current.snapshot.dialogue_position > initialDialogue.snapshot.dialogue_position) saved = current;
    }
    assert(saved, "dialogue did not advance after revealing its line");
    assert.equal(saved.snapshot.slot, 1);
    assert.equal(saved.snapshot.phase, "bedroom");
    await page.waitForTimeout(300);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.58);
    await page.waitForTimeout(150);
    await page.screenshot({ path: "build/web/dialogue_history.png" });
    await page.keyboard.press("Escape");
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
            record.snapshot.dialogue_history = [];
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
            record.snapshot.dialogue_history = [];
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
    const beforeChoice = await readStore("save_snapshots", 1);
    await page.keyboard.press("2");
    await page.waitForTimeout(200);
    await page.screenshot({ path: "build/web/preview_choice_confirm.png" });
    assert.deepEqual((await readStore("save_snapshots", 1)).snapshot, beforeChoice.snapshot,
      "unconfirmed choice changed IndexedDB");
    await page.keyboard.press("Escape");
    await page.waitForTimeout(150);
    assert.deepEqual((await readStore("save_snapshots", 1)).snapshot, beforeChoice.snapshot,
      "cancelled choice changed IndexedDB");
    await page.keyboard.press("2");
    await page.waitForTimeout(150);
    await page.keyboard.press("Enter");
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
    await page.waitForTimeout(150);
    assert.equal((await readStore("save_snapshots", 1)).snapshot.preview_choices.D2_03_A, undefined);
    await page.keyboard.press("Enter");
    const arrowSelected = await waitForStore("save_snapshots", 1, (record) =>
      record?.snapshot?.preview_choices?.D2_03_A === "B");
    assert.equal(arrowSelected.snapshot.preview_step, 10);
    await page.waitForTimeout(600);
    await page.keyboard.press("p");
    await page.waitForTimeout(800);
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    await waitForStore("save_snapshots", 1, (record) => record?.snapshot?.music_volume === 75);
    await page.waitForTimeout(250);
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    await waitForStore("save_snapshots", 1, (record) => record?.snapshot?.effects_volume === 100);
    await page.waitForTimeout(250);
    for (let i = 0; i < 4; i++) await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    await waitForStore("save_snapshots", 1, (record) => record?.snapshot?.dialogue_speed === "fast");
    await page.screenshot({ path: "build/web/audio_settings.png" });
    await page.keyboard.press("p");
    await page.setViewportSize({ width: 600, height: 360 });
    await page.waitForTimeout(800);
    await page.screenshot({ path: "build/web/window_too_small.png" });
    await page.setViewportSize({ width: 1152, height: 672 });
    await page.waitForTimeout(600);
    await page.screenshot({ path: "build/web/window_restored_pause.png" });
    await page.setViewportSize({ width: 768, height: 448 });
    await page.waitForTimeout(600);
    await page.screenshot({ path: "build/web/window_minimum.png" });
    await page.setViewportSize({ width: 1152, height: 672 });
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
            Object.assign(record.snapshot, {
              phase: "courtyard", player_position: [374, 250], ui_modal: "",
              dialogue_key: "", dialogue_position: 0, dialogue_choice: "", dialogue_history: [],
              preview_scene: "", preview_step: 0, preview_choices: {}
            });
            record.snapshot.flags.wakeup_seen = true;
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
    await page.waitForTimeout(800);
    await page.screenshot({ path: "build/web/courtyard_characters.png" });
    await page.keyboard.press("f");
    await waitForStore("save_snapshots", 1, (record) => record?.snapshot?.dialogue_key === "courtyard");
    await page.waitForTimeout(250);
    await page.screenshot({ path: "build/web/courtyard_camila_dialogue.png" });
    const showExplorationPhase = async (phase, position, flags, screenshotName, mobaClass = "", extraWait = 0, uiModal = "") => {
      await page.evaluate(async ({ phase, position, flags, mobaClass, uiModal }) => {
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
              Object.assign(record.snapshot, {
                phase, player_position: position, flags, moba_class: mobaClass, moba_result: "", ui_modal: uiModal, dialogue_key: "",
                dialogue_position: 0, dialogue_choice: "", dialogue_history: [],
                preview_scene: "", preview_step: 0, preview_choices: {}
              });
              store.put(record);
            };
            transaction.oncomplete = resolve;
            transaction.onerror = () => reject(transaction.error);
          });
        } finally { db.close(); }
      }, { phase, position, flags, mobaClass, uiModal });
      await page.reload();
      await page.waitForFunction(() => !!globalThis.CentinelaStorage);
      await page.waitForTimeout(1000);
      await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
      await page.waitForTimeout(800 + extraWait);
      await page.screenshot({ path: `build/web/${screenshotName}` });
    };
    await showExplorationPhase("bedroom", [384, 280], { wakeup_seen: true }, "bedroom_objects.png");
    await showExplorationPhase("computer", [384, 320], { wakeup_seen: true, alarm: true, backpack: true, friends: true }, "computer_object.png");
    await showExplorationPhase("computer", [382, 225], { wakeup_seen: true, alarm: true, backpack: true, friends: true }, "computer_near_pc.png");
    await page.keyboard.press("f");
    await waitForStore("save_snapshots", 1, (record) => record?.snapshot?.ui_modal === "desktop");
    await page.screenshot({ path: "build/web/computer_desktop_locked.png" });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1000);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(800);
    assert.equal((await readStore("save_snapshots", 1)).snapshot.ui_modal, "desktop");
    await page.screenshot({ path: "build/web/computer_desktop_restored.png" });
    await showExplorationPhase("computer", [384, 320], { wakeup_seen: true, alarm: true, backpack: true, friends: true }, "class_selection.png", "", 0, "class");
    await showExplorationPhase("moba", [384, 320], { wakeup_seen: true, alarm: true, backpack: true, friends: true }, "moba_teams.png", "Defensor", 3500);
    assert.equal((await readStore("save_snapshots", 1)).snapshot.phase, "moba");
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
            Object.assign(record.snapshot, { phase: "preview", moba_result: "empate",
              preview_scene: "F02", preview_step: 9, preview_choices: { D1_02_A: "B" },
              ui_modal: "", dialogue_key: "", dialogue_position: 0,
              dialogue_choice: "", dialogue_history: [] });
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
    await page.keyboard.press("Enter");
    await waitForStore("save_snapshots", 1, (record) =>
      record?.snapshot?.flags?.preview_reviewed === true &&
      record?.snapshot?.preview_scene === "ENDINGS_INDEX" && record.snapshot.preview_step === 1);
    await page.screenshot({ path: "build/web/preview_complete.png" });
    await page.reload();
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1000);
    await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
    await page.waitForTimeout(500);
    assert.equal((await readStore("save_snapshots", 1)).snapshot.flags.preview_reviewed, true);
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
            Object.assign(record.snapshot, { phase: "preview", preview_scene: "D4_03_A",
              preview_step: 7, preview_choices: { D4_03_A: "B" },
              draft_content_version: "PLAYABLE_DRAFT_v0.1",
              flags: { ...record.snapshot.flags, draft_mode: true, draft_completed: false, draft_ending: "" } });
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
    await page.keyboard.press("Enter");
    await waitForStore("save_snapshots", 1, (record) => record?.snapshot?.preview_scene === "F02");
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
    await page.keyboard.press("Enter");
    await waitForStore("save_snapshots", 1, (record) =>
      record?.snapshot?.flags?.draft_completed === true &&
      record?.snapshot?.flags?.draft_ending === "F02" &&
      record?.snapshot?.preview_scene === "ENDINGS_INDEX" && record.snapshot.preview_step === 2);
    await page.screenshot({ path: "build/web/draft_complete.png" });
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
            Object.assign(record.snapshot, { phase: "result", preview_scene: "", preview_step: 0,
              preview_choices: {}, flags: { ...record.snapshot.flags, draft_mode: false,
                draft_completed: false, draft_ending: "" } });
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
    await page.screenshot({ path: "build/web/draft_entry.png" });
    await page.keyboard.press("Enter");
    await waitForStore("save_snapshots", 1, (record) =>
      record?.snapshot?.flags?.draft_mode === true &&
      record?.snapshot?.flags?.draft_exploring === true &&
      record?.snapshot?.preview_scene === "D1_02_A");
    await page.screenshot({ path: "build/web/draft_exploration_d1.png" });
    await page.keyboard.press("e");
    await waitForStore("save_snapshots", 1, (record) => record?.snapshot?.ui_modal === "phone");
    await page.waitForTimeout(500);
    await page.keyboard.press("Escape");
    await waitForStore("save_snapshots", 1, (record) => record?.snapshot?.ui_modal === "");
    await page.keyboard.down("d");
    await page.waitForTimeout(2700);
    await page.keyboard.up("d");
    await page.keyboard.down("w");
    await page.waitForTimeout(600);
    await page.keyboard.up("w");
    await page.keyboard.press("f");
    await waitForStore("save_snapshots", 1, (record) =>
      record?.snapshot?.flags?.draft_exploring === false &&
      record?.snapshot?.preview_scene === "D1_02_A" && record.snapshot.preview_step === 0);
    await page.screenshot({ path: "build/web/draft_d1_scene.png" });
    for (const [sceneId, filename] of [
      ["D2_03_A", "draft_exploration_d2.png"],
      ["D3_01_A", "draft_exploration_d3.png"],
      ["D4_01_A", "draft_exploration_d4.png"]
    ]) {
      await page.evaluate(async (nextScene) => {
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
              Object.assign(record.snapshot, { phase: "preview", preview_scene: nextScene,
                preview_step: 0, player_position: [180, 315], ui_modal: "",
                flags: { ...record.snapshot.flags, draft_exploring: true } });
              store.put(record);
            };
            transaction.oncomplete = resolve;
            transaction.onerror = () => reject(transaction.error);
          });
        } finally { db.close(); }
      }, sceneId);
      await page.reload();
      await page.waitForFunction(() => !!globalThis.CentinelaStorage);
      await page.waitForTimeout(1000);
      await page.mouse.click(canvas.x + canvas.width * 0.5, canvas.y + canvas.height * 0.41);
      await page.waitForTimeout(500);
      assert.equal((await readStore("save_snapshots", 1)).snapshot.flags.draft_exploring, true);
      await page.screenshot({ path: `build/web/${filename}` });
    }
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
