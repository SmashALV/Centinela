(function (root) {
  "use strict";

  const DB_NAME = "centinela_2_local_v1";
  const DB_VERSION = 1;
  const PROTOCOL_VERSION = 1;
  const LEASE_MS = 30000;
  function currentTabId() {
    const navigation = root.performance?.getEntriesByType?.("navigation")?.[0];
    try {
      const remembered = root.sessionStorage?.getItem("centinela_tab_id_v1");
      if (navigation?.type === "reload" && remembered) return remembered;
      const fresh = root.crypto.randomUUID();
      root.sessionStorage?.setItem("centinela_tab_id_v1", fresh);
      return fresh;
    } catch (_) {
      return root.crypto.randomUUID();
    }
  }
  const tabId = currentTabId();
  let databasePromise = null;

  function failure(code, message) {
    const error = new Error(message);
    error.code = code;
    return error;
  }

  function validSlot(slot) {
    return Number.isInteger(slot) && slot >= 1 && slot <= 3;
  }

  function openDatabase() {
    if (databasePromise) return databasePromise;
    databasePromise = new Promise((resolve, reject) => {
      const request = root.indexedDB.open(DB_NAME, DB_VERSION);
      request.onupgradeneeded = () => {
        const db = request.result;
        for (const [name, keyPath] of [
          ["save_slots", "slot"], ["save_snapshots", "slot"],
          ["event_outbox", "event_id"], ["sync_status", "slot"],
          ["save_credentials", "slot"], ["locks", "slot"],
          ["request_log", "request_id"]
        ]) {
          if (!db.objectStoreNames.contains(name)) db.createObjectStore(name, { keyPath });
        }
      };
      request.onsuccess = () => {
        const db = request.result;
        db.onversionchange = () => { db.close(); databasePromise = null; };
        resolve(db);
      };
      request.onerror = () => {
        databasePromise = null;
        reject(failure("STORAGE_ERROR", "No se pudo abrir IndexedDB"));
      };
      request.onblocked = () => {
        databasePromise = null;
        reject(failure("STORAGE_ERROR", "IndexedDB está bloqueada por otra versión"));
      };
    });
    return databasePromise;
  }

  function runTransaction(db, stores, mode, build) {
    return new Promise((resolve, reject) => {
      let transaction;
      try {
        transaction = db.transaction(stores, mode);
      } catch (error) {
        reject(failure("STORAGE_ERROR", String(error)));
        return;
      }
      let result;
      let knownError = null;
      const setResult = (value) => { result = value; };
      const abort = (code, message) => {
        knownError = failure(code, message);
        transaction.abort();
      };
      transaction.oncomplete = () => resolve(result);
      transaction.onabort = () => reject(knownError || failure("STORAGE_ERROR", "Transacción abortada"));
      transaction.onerror = () => { knownError ||= failure("STORAGE_ERROR", "Falló una operación IndexedDB"); };
      try {
        build(transaction, setResult, abort);
      } catch (error) {
        knownError = error.code ? error : failure("INVALID_REQUEST", String(error));
        transaction.abort();
      }
    });
  }

  function checkLock(lock, generation) {
    if (!lock || lock.tab_id !== tabId || lock.generation !== generation || lock.expires_at <= Date.now()) {
      throw failure("LOCK_LOST", "La pestaña ya no posee esta partida");
    }
  }

  function validateSnapshot(snapshot, slot) {
    if (!snapshot || typeof snapshot !== "object" || Array.isArray(snapshot) ||
        snapshot.slot !== slot || snapshot.schema_version !== 1 ||
        typeof snapshot.code !== "string" || typeof snapshot.phase !== "string") {
      throw failure("INVALID_REQUEST", "Snapshot inválido");
    }
  }

  async function listSlots() {
    const db = await openDatabase();
    return runTransaction(db, ["save_slots"], "readonly", (tx, done) => {
      const request = tx.objectStore("save_slots").getAll();
      request.onsuccess = () => done(request.result.map(({ slot, code, phase, sequence }) => ({ slot, code, phase, sequence })));
    });
  }

  async function loadSlot(slot) {
    if (!validSlot(slot)) throw failure("INVALID_REQUEST", "Ranura inválida");
    const db = await openDatabase();
    return runTransaction(db, ["save_snapshots"], "readonly", (tx, done) => {
      const request = tx.objectStore("save_snapshots").get(slot);
      request.onsuccess = () => done(request.result ? request.result.snapshot : null);
    });
  }

  async function acquireLock(slot) {
    if (!validSlot(slot)) throw failure("INVALID_REQUEST", "Ranura inválida");
    const db = await openDatabase();
    return runTransaction(db, ["locks"], "readwrite", (tx, done, abort) => {
      const store = tx.objectStore("locks");
      const request = store.get(slot);
      request.onsuccess = () => {
        const previous = request.result;
        const now = Date.now();
        if (previous && previous.expires_at > now && previous.tab_id !== tabId) {
          abort("LOCK_HELD", "La partida está abierta en otra pestaña");
          return;
        }
        const generation = previous && previous.tab_id === tabId && previous.expires_at > now
          ? previous.generation : (previous?.generation || 0) + 1;
        const lock = { slot, tab_id: tabId, generation, expires_at: now + LEASE_MS };
        store.put(lock);
        done({ slot, generation, expires_at: lock.expires_at });
      };
    });
  }

  async function renewLock(slot, generation) {
    if (!validSlot(slot) || !Number.isInteger(generation)) throw failure("INVALID_REQUEST", "Bloqueo inválido");
    const db = await openDatabase();
    return runTransaction(db, ["locks"], "readwrite", (tx, done, abort) => {
      const store = tx.objectStore("locks");
      const request = store.get(slot);
      request.onsuccess = () => {
        try { checkLock(request.result, generation); } catch (error) { abort(error.code, error.message); return; }
        const lock = { ...request.result, expires_at: Date.now() + LEASE_MS };
        store.put(lock);
        done({ slot, generation, expires_at: lock.expires_at });
      };
    });
  }

  async function releaseLock(slot, generation) {
    if (!validSlot(slot) || !Number.isInteger(generation)) throw failure("INVALID_REQUEST", "Bloqueo inválido");
    const db = await openDatabase();
    return runTransaction(db, ["locks"], "readwrite", (tx, done, abort) => {
      const store = tx.objectStore("locks");
      const request = store.get(slot);
      request.onsuccess = () => {
        try { checkLock(request.result, generation); } catch (error) { abort(error.code, error.message); return; }
        store.put({ ...request.result, expires_at: 0 });
        done({ released: true });
      };
    });
  }

  async function writeSnapshot(requestId, payload, eventMode) {
    const { slot, generation, snapshot } = payload;
    if (!validSlot(slot) || !Number.isInteger(generation)) throw failure("INVALID_REQUEST", "Ranura o generación inválida");
    validateSnapshot(snapshot, slot);
    const hasEvent = eventMode !== "none";
    if (hasEvent) {
      const event = payload.event;
      if (!event || typeof event.event_id !== "string" || !event.event_id ||
          !Number.isInteger(event.sequence) || event.sequence < 1) {
        throw failure("INVALID_REQUEST", "Evento inválido");
      }
      if (eventMode === "decision" &&
          (typeof event.decision_id !== "string" || !event.decision_id ||
           typeof event.choice_id !== "string" || !event.choice_id || event.kind !== "decision"))
        throw failure("INVALID_REQUEST", "Decisión inválida");
      if (eventMode === "descriptive" && event.kind === "decision")
        throw failure("INVALID_REQUEST", "Una decisión requiere guardado de decisión");
    }
    const db = await openDatabase();
    const operation = eventMode === "none" ? "save_snapshot" :
      eventMode === "decision" ? "save_decision_atomic" : "save_event_atomic";
    const signature = JSON.stringify(payload);
    const stores = ["locks", "save_slots", "save_snapshots", "request_log"];
    if (hasEvent) stores.push("event_outbox");
    return runTransaction(db, stores, "readwrite", (tx, done, abort) => {
      const oldRequest = tx.objectStore("request_log").get(requestId);
      oldRequest.onsuccess = () => {
        if (oldRequest.result) {
          if (oldRequest.result.operation !== operation || oldRequest.result.signature !== signature) {
            abort("INVALID_REQUEST", "request_id reutilizado con otro contenido");
          } else {
            done(oldRequest.result.result);
          }
          return;
        }
        const lockRequest = tx.objectStore("locks").get(slot);
        lockRequest.onsuccess = () => {
          try { checkLock(lockRequest.result, generation); } catch (error) { abort(error.code, error.message); return; }
          const continueWrite = () => {
            const metaRequest = tx.objectStore("save_slots").get(slot);
            metaRequest.onsuccess = () => {
            const previous = metaRequest.result;
            const sequence = previous?.sequence || 0;
            if (hasEvent && payload.event.sequence !== sequence + 1) {
              abort("INVALID_REQUEST", "Secuencia de evento no consecutiva");
              return;
            }
            const saveId = previous?.save_id || root.crypto.randomUUID();
            const nextSequence = hasEvent ? sequence + 1 : sequence;
            const result = { slot, save_id: saveId, sequence: nextSequence };
            tx.objectStore("save_slots").put({ slot, save_id: saveId, code: snapshot.code,
              phase: snapshot.phase, sequence: nextSequence });
            tx.objectStore("save_snapshots").put({ slot, snapshot });
            if (hasEvent) {
              tx.objectStore("event_outbox").put({ event_id: payload.event.event_id,
                slot, sequence: nextSequence, payload: payload.event });
            }
            tx.objectStore("request_log").put({ request_id: requestId, operation, signature, result });
            done(result);
            };
          };
          if (hasEvent) {
            const eventRequest = tx.objectStore("event_outbox").get(payload.event.event_id);
            eventRequest.onsuccess = () => {
              if (eventRequest.result) abort("INVALID_REQUEST", "event_id ya registrado");
              else continueWrite();
            };
          } else continueWrite();
        };
      };
    });
  }

  async function credentialOperation(operation, payload) {
    const { slot, generation } = payload;
    if (!validSlot(slot) || !Number.isInteger(generation)) throw failure("INVALID_REQUEST", "Bloqueo inválido");
    const db = await openDatabase();
    const stores = operation === "get_slot_meta" ? ["locks", "save_slots"] :
      operation === "peek_outbox" ? ["locks", "event_outbox"] :
      operation === "ack_outbox" ? ["locks", "event_outbox", "sync_status"] :
      operation === "get_sync_status" || operation === "set_sync_status" ? ["locks", "sync_status"] :
      ["locks", "save_credentials"];
    const mode = ["put_credential", "ack_outbox", "set_sync_status"].includes(operation) ? "readwrite" : "readonly";
    return runTransaction(db, stores, mode, (tx, done, abort) => {
      const lockRequest = tx.objectStore("locks").get(slot);
      lockRequest.onsuccess = () => {
        try { checkLock(lockRequest.result, generation); } catch (error) { abort(error.code, error.message); return; }
        if (operation === "get_slot_meta") {
          const request = tx.objectStore("save_slots").get(slot);
          request.onsuccess = () => done(request.result || null);
        } else if (operation === "get_credential") {
          const request = tx.objectStore("save_credentials").get(slot);
          request.onsuccess = () => done(request.result?.credential || null);
        } else if (operation === "put_credential") {
          const credential = payload.credential;
          const pendingRegistration = typeof credential?.registration_id === "string" &&
            credential.save_id === undefined && credential.recovery_secret === undefined;
          const completeCredential = typeof credential?.save_id === "string" &&
            typeof credential?.recovery_secret === "string";
          if (!pendingRegistration && !completeCredential) {
            abort("INVALID_REQUEST", "Credencial inválida"); return;
          }
          tx.objectStore("save_credentials").put({ slot, credential });
          done({ stored: true });
        } else if (operation === "peek_outbox") {
          const request = tx.objectStore("event_outbox").getAll();
          request.onsuccess = () => done(request.result.filter((entry) => entry.slot === slot)
            .sort((a, b) => a.sequence - b.sequence).slice(0, 10).map((entry) => entry.payload));
        } else if (operation === "ack_outbox") {
          const receipts = payload.receipts;
          if (!Array.isArray(receipts) || receipts.length > 10) {
            abort("INVALID_REQUEST", "Acuses inválidos"); return;
          }
          const result = { acknowledged: 0 };
          for (const receipt of receipts) {
            if (!receipt || typeof receipt.event_id !== "string" ||
                !["accepted", "duplicate"].includes(receipt.status)) continue;
            const request = tx.objectStore("event_outbox").get(receipt.event_id);
            request.onsuccess = () => {
              if (request.result?.slot === slot) {
                tx.objectStore("event_outbox").delete(receipt.event_id);
                result.acknowledged += 1;
              }
            };
          }
          done(result);
        } else if (operation === "get_sync_status") {
          const request = tx.objectStore("sync_status").get(slot);
          request.onsuccess = () => done(request.result?.status || null);
        } else if (operation === "set_sync_status") {
          const status = payload.status;
          if (!status || typeof status !== "object" || Array.isArray(status)) {
            abort("INVALID_REQUEST", "Estado inválido"); return;
          }
          tx.objectStore("sync_status").put({ slot, status });
          done({ stored: true });
        }
      };
    });
  }

  async function dispatch(request) {
    if (!request || request.protocol_version !== PROTOCOL_VERSION || typeof request.request_id !== "string" || !request.request_id) {
      throw failure("PROTOCOL_MISMATCH", "Protocolo o request_id inválido");
    }
    const payload = request.payload || {};
    switch (request.operation) {
      case "list_slots": return listSlots();
      case "load_slot": return loadSlot(payload.slot);
      case "acquire_lock": return acquireLock(payload.slot);
      case "renew_lock": return renewLock(payload.slot, payload.generation);
      case "release_lock": return releaseLock(payload.slot, payload.generation);
      case "save_snapshot": return writeSnapshot(request.request_id, payload, "none");
      case "save_decision_atomic": return writeSnapshot(request.request_id, payload, "decision");
      case "save_event_atomic": return writeSnapshot(request.request_id, payload, "descriptive");
      case "get_slot_meta": case "get_credential": case "put_credential": case "peek_outbox":
      case "ack_outbox": case "get_sync_status": case "set_sync_status":
        return credentialOperation(request.operation, payload);
      default: throw failure("INVALID_REQUEST", "Operación desconocida");
    }
  }

  function request(raw, callback) {
    let requestId = "";
    try { requestId = JSON.parse(raw)?.request_id || ""; } catch (_) { /* respuesta con ID vacío */ }
    Promise.resolve().then(() => dispatch(JSON.parse(raw)))
      .then((result) => callback(JSON.stringify({ request_id: requestId, success: true, result })))
      .catch((error) => callback(JSON.stringify({ request_id: requestId, success: false,
        error: { code: error.code || "STORAGE_ERROR", message: error.message || "Error de almacenamiento" } })));
  }

  root.CentinelaStorage = { request };
})(globalThis);
