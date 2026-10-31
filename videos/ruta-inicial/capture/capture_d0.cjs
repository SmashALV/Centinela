// Captura las pantallas del Día 0 desde la exportación Web (build/web).
// Ejecutar desde la raíz del repositorio: node videos/ruta-inicial/capture/capture_d0.cjs
const { createServer } = require("node:http");
const { readFile } = require("node:fs/promises");
const path = require("node:path");
const { chromium } = require("playwright-core");

const root = path.resolve("build/web");
const out = path.resolve("videos/ruta-inicial/public/capturas");
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
    executablePath: process.env.CENTINELA_BROWSER_EXE || "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    headless: true, args: ["--enable-webgl", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"]
  });
  try {
    const page = await browser.newPage({ viewport: { width: 1152, height: 672 } });
    await page.goto(`http://127.0.0.1:${server.address().port}/index.html`);
    await page.waitForFunction(() => !!globalThis.CentinelaStorage);
    await page.waitForTimeout(1500);
    const canvas = await page.locator("canvas").boundingBox();
    const shot = async (name) => { await page.screenshot({ path: path.join(out, name + ".png") }); console.log("ok", name); };
    const readSave = () => page.evaluate(async () => {
      const db = await new Promise((resolve, reject) => { const r = indexedDB.open("centinela_2_local_v1"); r.onsuccess = () => resolve(r.result); r.onerror = () => reject(r.error); });
      try {
        return await new Promise((resolve, reject) => {
          const r = db.transaction("save_snapshots").objectStore("save_snapshots").get(1);
          r.onsuccess = () => resolve(r.result?.snapshot || null); r.onerror = () => reject(r.error);
        });
      } finally { db.close(); }
    });
    const waitFor = async (predicate, label) => {
      const until = Date.now() + 90000;
      while (Date.now() < until) {
        const state = await readSave();
        if (predicate(state)) { await page.waitForTimeout(300); return state; }
        await page.waitForTimeout(120);
      }
      await shot("_fallo");
      throw new Error("Timeout " + label + ": " + JSON.stringify(await readSave()));
    };
    const click = (x, y) => page.mouse.click(canvas.x + canvas.width * x / 768, canvas.y + canvas.height * y / 448);
    const move = async (key, ms) => { await page.keyboard.down(key); await page.waitForTimeout(ms); await page.keyboard.up(key); await page.waitForTimeout(250); };
    const seed = async (overrides) => {
      const changes = { dialogue_key: "", dialogue_position: 0, dialogue_history: [], dialogue_choice: "", ...overrides };
      await page.evaluate(async changes => {
        const db = await new Promise((resolve, reject) => { const r = indexedDB.open("centinela_2_local_v1"); r.onsuccess = () => resolve(r.result); r.onerror = () => reject(r.error); });
        await new Promise((resolve, reject) => {
          const tx = db.transaction("save_snapshots", "readwrite"), store = tx.objectStore("save_snapshots"), r = store.get(1);
          r.onsuccess = () => { const row = r.result; Object.assign(row.snapshot, changes); store.put(row); };
          tx.oncomplete = resolve; tx.onerror = () => reject(tx.error);
        });
        db.close();
      }, changes);
      await page.reload(); await page.waitForFunction(() => !!globalThis.CentinelaStorage); await page.waitForTimeout(1300);
      await click(384, 183); await page.waitForTimeout(900);
    };
    const routine = (stage, place, scene = "", step = 0) => ({ version: "DAILY_v1", day: 0, stage, place, scene, step, chat_seen: false, matches: [], messages_checked: true });

    // Menú, prólogo y despertar
    await shot("01_menu");
    await click(384, 183);
    await waitFor(s => s?.flags?.routine?.stage === "morning", "prologo");
    await page.waitForTimeout(600);
    await shot("02_prologo");
    await click(384, 320);
    await waitFor(s => s?.dialogue_key === "wakeup", "despertar");
    await page.waitForTimeout(500);
    await shot("03_despertar");
    for (let i = 0; i < 3; i++) { await click(384, 320); await page.waitForTimeout(450); }
    await waitFor(s => s?.flags?.wakeup_seen === true && !s.dialogue_key, "fin despertar");
    await shot("04_habitacion");
    await page.keyboard.press("e"); await waitFor(s => s?.ui_modal === "phone", "celular");
    await shot("05_celular");
    await page.keyboard.press("Escape"); await waitFor(s => !s?.ui_modal, "cerrar celular");
    await page.keyboard.press("Tab"); await page.waitForTimeout(700);
    await shot("06_objetivo_pistas");
    await page.keyboard.press("Escape"); await page.waitForTimeout(500);
    await move("d", 1300); await page.keyboard.press("f"); await waitFor(s => s?.flags?.backpack === true, "mochila");
    await shot("07_mochila");
    const base = await readSave();

    // Foto de la habitación
    await seed({ phase: "bedroom", flags: { ...base.flags, routine: routine("morning", "bedroom") }, player_position: [494, 172], ui_modal: "" });
    await page.keyboard.press("f"); await page.waitForTimeout(800);
    await shot("08_foto");

    // Desayuno y calle
    await seed({ phase: "bedroom", flags: { ...base.flags, routine: routine("breakfast", "living", "breakfast", 1) }, player_position: [370, 250], ui_modal: "" });
    await shot("09_desayuno");
    await seed({ phase: "courtyard", flags: { ...base.flags, routine: routine("outbound", "street") }, player_position: [300, 285], ui_modal: "" });
    await shot("10_calle_manana");

    // Colegio: grupo, conversación, tutoría y cómputo
    await seed({ phase: "courtyard", flags: { ...base.flags, routine: routine("arrival", "school") }, player_position: [385, 330], ui_modal: "" });
    await shot("11_colegio");
    await seed({ phase: "courtyard", flags: { ...base.flags, routine: routine("arrival", "school") }, player_position: [374, 280], ui_modal: "" });
    await page.keyboard.press("f");
    await waitFor(s => s?.dialogue_key === "courtyard", "patio");
    await page.waitForTimeout(500);
    await shot("12_patio_camila");
    for (let i = 0; i < 2; i++) { await click(384, 320); await page.waitForTimeout(500); }
    await shot("13_patio_mateo");
    for (let i = 0; i < 3; i++) { await click(384, 320); await page.waitForTimeout(500); }
    await shot("14_patio_bruno");
    await seed({ phase: "courtyard", dialogue_key: "", dialogue_position: 0, flags: { ...base.flags, friends: true, routine: routine("arrival", "tutor") }, player_position: [380, 280], ui_modal: "" });
    await shot("15_tutoria_mapa");
    await page.keyboard.press("f"); await page.waitForTimeout(800);
    await shot("16_tutoria_cartel");
    await seed({ phase: "computer", flags: { ...base.flags, friends: true, routine: routine("arrival", "computer") }, player_position: [382, 255], ui_modal: "" });
    await shot("17_sala_computo");

    // Clase
    await seed({ phase: "courtyard", flags: { ...base.flags, friends: true, routine: routine("class", "classroom") }, player_position: [385, 330], ui_modal: "" });
    await shot("18_salon");
    await seed({ phase: "courtyard", flags: { ...base.flags, friends: true, routine: routine("class", "classroom", "lesson", 1) }, player_position: [385, 300], ui_modal: "" });
    await shot("19_clase_mateo");
    for (let i = 0; i < 3; i++) { await click(384, 320); await page.waitForTimeout(450); }
    await waitFor(s => s?.flags?.routine?.stage === "class_exit", "campana");
    await shot("20_campana");

    // Despedida y regreso
    await seed({ phase: "courtyard", flags: { ...base.flags, friends: true, farewell_done: false, routine: routine("farewell", "school", "goodbye", 0) }, player_position: [385, 250], ui_modal: "" });
    await shot("21_despedida");
    await seed({ phase: "courtyard", flags: { ...base.flags, friends: true, farewell_done: false, routine: routine("homeward", "street") }, player_position: [420, 285], ui_modal: "" });
    await shot("22_calle_atardecer");

    // Cena y escritorio
    await seed({ phase: "bedroom", flags: { ...base.flags, friends: true, routine: routine("dinner", "living", "dinner", 1) }, player_position: [370, 250], ui_modal: "" });
    await shot("23_cena");
    await seed({ phase: "computer", flags: { ...base.flags, friends: true, d0_chat_done: false, routine: routine("evening", "bedroom") }, player_position: [310, 230], ui_modal: "desktop" });
    await shot("24_escritorio_bloqueado");

    // Discord: chat del grupo y decisión
    await click(78, 105);
    await waitFor(s => s?.dialogue_key === "group_chat", "chat grupo");
    await page.waitForTimeout(800);
    await shot("25_discord_inicio");
    for (let i = 0; i < 8; i++) {
      const s = await readSave();
      if (s?.dialogue_position >= 19) break;
      await click(450, 300); await page.waitForTimeout(600);
    }
    await page.waitForTimeout(800);
    await shot("26_discord_decision");
    await click(458, 342);
    await waitFor(s => s?.flags?.d0_chat_done === true, "decision");
    console.log("eleccion", (await readSave()).flags.d0_chat_choice);
    await page.waitForTimeout(900);
    await shot("27_escritorio_habilitado");
    await click(78, 105); await page.waitForTimeout(900);
    await shot("28_discord_respuesta");
    await page.keyboard.press("Escape"); await page.waitForTimeout(500);

    // Arena 5v5
    const afterChat = await readSave();
    await seed({ ...afterChat, ui_modal: "desktop" });
    await click(205, 105); await waitFor(s => s?.ui_modal === "class", "clase");
    await shot("29_clases");
    await click(384, 139); await waitFor(s => s?.phase === "moba", "moba");
    await page.waitForTimeout(4000); await shot("30_moba_inicio");
    await page.mouse.move(canvas.x + canvas.width * 0.8, canvas.y + canvas.height * 0.5);
    await page.keyboard.down("d"); await page.waitForTimeout(2500); await page.keyboard.up("d");
    for (let i = 0; i < 12; i++) { await page.mouse.down(); await page.waitForTimeout(120); await page.mouse.up(); await page.waitForTimeout(150); }
    await page.keyboard.press("q");
    await page.waitForTimeout(800); await shot("31_moba_combate");
    await waitFor(s => s?.phase === "result", "resultado");
    await shot("32_moba_resultado");
    await page.keyboard.press("Enter");
    await waitFor(s => s?.flags?.routine?.scene === "match_reply" || s?.flags?.routine?.stage === "bedtime", "reaccion");
    await page.waitForTimeout(900);
    await shot("33_reaccion_camila");
    console.log("resultado", (await readSave()).moba_result);
    for (let i = 0; i < 2; i++) { await click(450, 405); await page.waitForTimeout(600); }
    await waitFor(s => s?.flags?.routine?.stage === "bedtime", "hora de dormir");
    await page.waitForTimeout(600);
    await shot("34_hora_dormir");

    // Dormir y Día 1
    const night = await readSave();
    await seed({ ...night, phase: "computer", flags: { ...night.flags, routine: { ...night.flags.routine, stage: "sleep" } }, player_position: [155, 208] });
    await page.waitForTimeout(500); await shot("35_dormir");
    await page.waitForTimeout(2200); await shot("36_amanece");
    await waitFor(s => s?.flags?.routine?.day === 1 && s?.flags?.routine?.stage === "morning", "dia 1");
    await page.waitForTimeout(700);
    await shot("37_dia1");
  } finally { await browser.close(); await new Promise(resolve => server.close(resolve)); }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
