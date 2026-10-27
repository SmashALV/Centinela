(function (root) {
  "use strict";

  let active = null;
  const pending = new Map();

  function failure(code, message) {
    const error = new Error(message);
    error.code = code;
    return error;
  }

  function local(operation, payload) {
    return new Promise((resolve, reject) => {
      root.CentinelaStorage.request(JSON.stringify({ protocol_version: 1,
        request_id: root.crypto.randomUUID(), operation, payload }), (raw) => {
        const result = JSON.parse(raw);
        if (result.success) resolve(result.result);
        else reject(failure(result.error?.code || "STORAGE_ERROR", "Falló IndexedDB"));
      });
    });
  }

  function validConfig(config) {
    if (!config || typeof config !== "object" || typeof config.url !== "string" ||
        typeof config.public_key !== "string" || typeof config.rubric_version !== "string") return false;
    try {
      const url = new URL(config.url);
      return (url.protocol === "https:" || (url.protocol === "http:" &&
        ["localhost", "127.0.0.1"].includes(url.hostname))) && !!config.public_key &&
        /^[A-Za-z0-9_.-]{1,80}$/.test(config.rubric_version);
    } catch (_) { return false; }
  }

  async function fetchJson(url, options) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    try {
      const response = await root.fetch(url, { ...options, signal: controller.signal });
      const body = await response.json().catch(() => ({}));
      if (!response.ok) throw failure(response.status === 401 ? "UNAUTHORIZED" :
        response.status === 429 ? "RATE_LIMITED" :
        response.status >= 500 ? "TRANSIENT_BACKEND" : "BACKEND_REJECTED",
      typeof body.error === "string" ? body.error : "Solicitud rechazada");
      return body;
    } catch (error) {
      if (error.code) throw error;
      throw failure("OFFLINE", "No se pudo conectar al backend");
    } finally {
      clearTimeout(timeout);
    }
  }

  async function signIn(config) {
    const session = await fetchJson(`${config.url}/auth/v1/signup`, {
      method: "POST", headers: { apikey: config.public_key, "Content-Type": "application/json" },
      body: "{}"
    });
    if (typeof session.access_token !== "string" || typeof session.refresh_token !== "string")
      throw failure("BACKEND_REJECTED", "Respuesta de autenticación incompleta");
    return session;
  }

  async function refreshToken(state) {
    const session = await fetchJson(`${state.config.url}/auth/v1/token?grant_type=refresh_token`, {
      method: "POST", headers: { apikey: state.config.public_key, "Content-Type": "application/json" },
      body: JSON.stringify({ refresh_token: state.refresh_token })
    });
    if (typeof session.access_token !== "string" || typeof session.refresh_token !== "string")
      throw failure("UNAUTHORIZED", "No se pudo renovar la sesión");
    state.access_token = session.access_token;
    state.refresh_token = session.refresh_token;
  }

  async function edge(state, operation, body) {
    const send = () => fetchJson(`${state.config.url}/functions/v1/${operation}`, {
      method: "POST", headers: { apikey: state.config.public_key,
        Authorization: `Bearer ${state.access_token}`, "Content-Type": "application/json" },
      body: JSON.stringify(body)
    });
    try { return await send(); }
    catch (error) {
      if (error.code !== "UNAUTHORIZED") throw error;
      await refreshToken(state);
      return send();
    }
  }

  async function open(payload) {
    const { slot, generation, code, narrative_version } = payload;
    const config = payload.config && { ...payload.config,
      url: String(payload.config.url || "").replace(/\/+$/, "") };
    if (!Number.isInteger(slot) || slot < 1 || slot > 3 || !Number.isInteger(generation) ||
        typeof code !== "string" || !/^CTN-[0-9]{6}$/.test(code) ||
        typeof narrative_version !== "string" || !validConfig(config))
      throw failure("INVALID_REQUEST", "Configuración de sincronización inválida");
    if (active?.slot === slot && active.generation === generation)
      return { save_id: active.save_id, code: active.code, connected: true };
    const lock = { slot, generation };
    let credential = await local("get_credential", lock);
    if (!credential) {
      credential = { registration_id: root.crypto.randomUUID() };
      await local("put_credential", { ...lock, credential });
    }
    const session = await signIn(config);
    const state = { slot, generation, config, access_token: session.access_token,
      refresh_token: session.refresh_token, save_id: "", code };
    let server;
    if (credential.save_id && credential.recovery_secret) {
      server = await edge(state, "claim_save", { save_id: credential.save_id,
        recovery_secret: credential.recovery_secret });
    } else {
      server = await edge(state, "register_save", { registration_id: credential.registration_id,
        code, narrative_version, rubric_version: config.rubric_version });
      if (typeof server.save_id !== "string" || typeof server.recovery_secret !== "string")
        throw failure("BACKEND_REJECTED", "Registro incompleto");
      credential = { save_id: server.save_id, recovery_secret: server.recovery_secret };
      await local("put_credential", { ...lock, credential });
    }
    state.save_id = server.save_id;
    state.code = server.code || code;
    active = state;
    await local("set_sync_status", { ...lock, status: { connected: true,
      last_sequence: server.last_sequence || 0, sync_completed: !!server.sync_completed } });
    return { save_id: state.save_id, code: state.code, connected: true };
  }

  async function flush(payload) {
    const state = active;
    if (!state || state.slot !== payload.slot || state.generation !== payload.generation)
      throw failure("NOT_CONNECTED", "La partida no está conectada");
    const lock = { slot: state.slot, generation: state.generation };
    const events = await local("peek_outbox", lock);
    if (!events.length) return { sent: 0, pending: 0 };
    const receipt = await edge(state, "ingest_events", { save_id: state.save_id, events });
    if (!Array.isArray(receipt.receipts)) throw failure("BACKEND_REJECTED", "Acuse inválido");
    await local("ack_outbox", { ...lock, receipts: receipt.receipts });
    const remaining = await local("peek_outbox", lock);
    const rejected = receipt.receipts.find((item) => !["accepted", "duplicate"].includes(item.status));
    await local("set_sync_status", { ...lock, status: { connected: true,
      last_sequence: receipt.last_sequence, sync_completed: !!receipt.sync_completed,
      last_error: rejected?.status || "" } });
    if (rejected) throw failure("EVENT_REJECTED", rejected.status);
    return { sent: receipt.receipts.length, pending: remaining.length,
      sync_completed: !!receipt.sync_completed };
  }

  async function finalize(payload) {
    const state = active;
    if (!state || state.slot !== payload.slot || state.generation !== payload.generation ||
        !Number.isInteger(payload.last_sequence) || payload.last_sequence < 0)
      throw failure("INVALID_REQUEST", "Finalización inválida");
    const result = await edge(state, "finalize_sync", { save_id: state.save_id,
      last_sequence: payload.last_sequence });
    await local("set_sync_status", { slot: state.slot, generation: state.generation,
      status: { connected: true, last_sequence: result.last_sequence,
        sync_completed: !!result.sync_completed, story_completed: true } });
    return result;
  }

  function request(raw, callback) {
    let parsed;
    try { parsed = JSON.parse(raw); } catch (_) {
      callback(JSON.stringify({ request_id: "", success: false, error: { code: "INVALID_REQUEST" } }));
      return;
    }
    const id = parsed.request_id || "";
    if (parsed.protocol_version !== 1 || !id) {
      callback(JSON.stringify({ request_id: id, success: false, error: { code: "PROTOCOL_MISMATCH" } }));
      return;
    }
    if (!pending.has(id)) {
      const work = Promise.resolve().then(() => {
        if (parsed.operation === "sync_open") return open(parsed.payload || {});
        if (parsed.operation === "sync_flush") return flush(parsed.payload || {});
        if (parsed.operation === "sync_finalize") return finalize(parsed.payload || {});
        if (parsed.operation === "sync_close") {
          if (active?.slot === parsed.payload?.slot &&
              active?.generation === parsed.payload?.generation) active = null;
          return { closed: true };
        }
        throw failure("INVALID_REQUEST", "Operación desconocida");
      }).then((result) => ({ request_id: id, success: true, result }))
        .catch((error) => ({ request_id: id, success: false,
          error: { code: error.code || "BACKEND_ERROR", message: error.message || "Error de sincronización" } }));
      pending.set(id, work);
      if (pending.size > 100) pending.delete(pending.keys().next().value);
    }
    pending.get(id).then((result) => callback(JSON.stringify(result)));
  }

  root.CentinelaSync = { request };
})(globalThis);
