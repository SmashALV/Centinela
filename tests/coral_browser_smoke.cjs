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
      const until = Date.now() + 90000;
      while (Date.now() < until) {
        const state = await readSave();
        if (predicate(state)) {
          await page.waitForTimeout(250);
          return state;
        }
        await page.waitForTimeout(120);
      }
      await page.screenshot({path:"build/web/daily_failure.png"});
      throw new Error("Timed out waiting for state: "+JSON.stringify(await readSave()));
    };

    const click = (x, y) => page.mouse.click(canvas.x + canvas.width*x/768, canvas.y + canvas.height*y/448);
    const move = async (key, ms) => { await page.keyboard.down(key); await page.waitForTimeout(ms); await page.keyboard.up(key); await page.waitForTimeout(200); };
    const travel = async (key, place) => { await page.keyboard.down(key); try { await waitFor(s=>s?.flags?.routine?.place===place); } finally { await page.keyboard.up(key); } await page.waitForTimeout(200); };
    const seed = async (changes) => {
      await page.evaluate(async changes => {
        const db = await new Promise((resolve,reject) => { const r=indexedDB.open("centinela_2_local_v1");r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error); });
        await new Promise((resolve,reject) => { const tx=db.transaction("save_snapshots","readwrite"), store=tx.objectStore("save_snapshots"),r=store.get(1);
          r.onsuccess=()=>{const row=r.result;Object.assign(row.snapshot,changes);store.put(row);};tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error); });db.close();
      },changes);
      await page.reload();await page.waitForFunction(()=>!!globalThis.CentinelaStorage);await page.waitForTimeout(1200);await click(384,183);await page.waitForTimeout(700);
    };
    await click(384,183);
    await waitFor(s=>s?.flags?.routine?.stage==="morning");
    await page.screenshot({path:"build/web/daily_prologue.png"});
    await click(384,320);
    await waitFor(s=>s?.dialogue_key==="wakeup");
    for(let i=0;i<3;i++){await click(384,320);await page.waitForTimeout(400);}
    await waitFor(s=>s?.flags?.wakeup_seen===true && !s.dialogue_key);
    await page.keyboard.press("e");await waitFor(s=>s?.ui_modal==="phone");await page.keyboard.press("Escape");await waitFor(s=>!s?.ui_modal);
    await move("d",1300);await page.keyboard.press("f");await waitFor(s=>s?.flags?.backpack===true);
    await move("d",1000);await waitFor(s=>s?.flags?.routine?.place==="living");
    await page.screenshot({path:"build/web/daily_living_map.png"});
    const base=await readSave();
    const routine = (day,stage,place,scene="",step=0)=>({version:"DAILY_v1",day,stage,place,scene,step,chat_seen:day>0,matches:[],messages_checked:true});
    if(process.env.CENTINELA_SLEEP_ONLY === "1") {
      await seed({phase:"computer",flags:{...base.flags,d0_chat_done:true,routine:routine(0,"evening","bedroom")},text_size:"large",ui_modal:"desktop",player_position:[310,230]});
      await page.screenshot({path:"build/web/daily_desktop_large.png"});
      await seed({phase:"computer",flags:{...base.flags,routine:routine(0,"sleep","bedroom")},text_size:"normal",ui_modal:"",player_position:[155,208]});
      await page.screenshot({path:"build/web/daily_sleep.png"});
      await waitFor(s=>s?.flags?.routine?.day===1 && s?.flags?.routine?.stage==="morning");
      assert.deepEqual(errors,[]);console.log("PASS Web: sprite dormida en cama y despertar D1");return;
    }
    await seed({phase:"bedroom",flags:{...base.flags,routine:routine(0,"breakfast","living","breakfast")},player_position:[370,250],ui_modal:""});
    await page.screenshot({path:"build/web/daily_breakfast_vn.png"});
    await click(384,320);await page.waitForTimeout(300);await click(384,320);
    await waitFor(s=>s?.flags?.routine?.stage==="outbound");
    await travel("d","street");
    await page.screenshot({path:"build/web/daily_street_morning.png"});
    const coral={version:"CORAL_STORY_v0.2",day:1,mode:"explore",node:"",step:0,route:"",branch:"",focus:"",choices:{},companion_states:{},actions:[],observed:[],seen_narrator:[],hint_requests:{},adult_support_started:false,limit_completed:false,chapter_scene_done:false,ending:""};
    await seed({phase:"coral",coral_state:coral,flags:{...base.flags,routine:routine(1,"arrival","school")},player_position:[384,320],ui_modal:""});
    await page.screenshot({path:"build/web/daily_school_group.png"});
    await seed({phase:"coral",coral_state:{...coral,mode:"scene",node:"I_D1_CAMILA"},flags:{...base.flags,routine:routine(1,"arrival","computer")},player_position:[384,300],ui_modal:""});
    await page.screenshot({path:"build/web/daily_lab_vn.png"});
    await seed({phase:"coral",coral_state:{...coral,day:2,mode:"scene",node:"D2_B"},flags:{...base.flags,routine:routine(2,"arrival","school")},player_position:[384,300],ui_modal:""});
    await page.screenshot({path:"build/web/daily_mateo_vn.png"});
    await seed({phase:"coral",coral_state:coral,flags:{...base.flags,routine:routine(1,"class","classroom","lesson",1)},player_position:[384,300],ui_modal:""});
    await page.screenshot({path:"build/web/daily_classroom_vn.png"});
    for(let i=0;i<3;i++){await click(384,320);await page.waitForTimeout(350);}
    await waitFor(s=>s?.flags?.routine?.stage==="class_exit");
    await page.screenshot({path:"build/web/daily_classroom_map.png"});
    await travel("s","school");
    await page.screenshot({path:"build/web/daily_farewell_map.png"});
    await seed({phase:"coral",coral_state:coral,flags:{...base.flags,routine:routine(1,"homeward","street")},player_position:[380,285],ui_modal:""});
    await page.screenshot({path:"build/web/daily_street_sunset.png"});
    await seed({phase:"computer",coral_state:{},flags:{...base.flags,d0_chat_done:true,routine:routine(0,"evening","bedroom")},player_position:[310,230],ui_modal:"desktop"});
    await page.screenshot({path:"build/web/daily_desktop.png"});
    await click(78,105);await page.waitForTimeout(900);await page.screenshot({path:"build/web/daily_discord_history.png"});
    await click(550,25);await page.waitForTimeout(700);await page.screenshot({path:"build/web/daily_private_history.png"});
    await page.keyboard.press("Escape");await page.waitForTimeout(500);

    await click(205,105);await waitFor(s=>s?.ui_modal==="class");
    await click(384,139);await waitFor(s=>s?.phase==="moba");
    await page.waitForTimeout(7000);await page.screenshot({path:"build/web/daily_arena.png"});
    await waitFor(s=>s?.phase==="result");
    await page.screenshot({path:"build/web/daily_arena_result.png"});
    await page.keyboard.press("Enter");await waitFor(s=>s?.flags?.routine?.scene==="match_reply" || s?.flags?.routine?.stage==="bedtime");
    for(let i=0;i<2;i++){await click(450,405);await page.waitForTimeout(500);}
    await waitFor(s=>s?.flags?.routine?.stage==="bedtime");
    await seed({phase:"computer",flags:{...base.flags,routine:routine(0,"sleep","bedroom")},text_size:"normal",ui_modal:"",player_position:[155,208]});
    await page.waitForTimeout(650);await page.screenshot({path:"build/web/daily_sleep.png"});
    await waitFor(s=>s?.flags?.routine?.day===1 && s?.flags?.routine?.stage==="morning");
    await page.screenshot({path:"build/web/daily_next_morning.png"});
    assert.deepEqual(errors,[]);
    console.log("PASS Web: rutina, bordes reales, fondos, sprites, escritorio, partida y despertar D1");
  } finally { await browser.close(); await new Promise(resolve=>server.close(resolve)); }
}
main().catch(error=>{console.error(error);process.exitCode=1;});
