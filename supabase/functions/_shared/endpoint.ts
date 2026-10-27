import { createClient } from "npm:@supabase/supabase-js@2";

type Json = Record<string, unknown>;
type Admin = { rpc: (name: string, args: Json) => Promise<{
  data: unknown; error: { code?: string } | null;
}> };
type Handler = (body: Json, owner: string, admin: Admin) => Promise<Json>;

function response(body: Json, status: number, origin: string | null): Response {
  const headers = new Headers({ "Content-Type": "application/json", "Cache-Control": "no-store" });
  if (origin) {
    headers.set("Access-Control-Allow-Origin", origin);
    headers.set("Vary", "Origin");
    headers.set("Access-Control-Allow-Headers", "authorization, apikey, content-type");
    headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  }
  return new Response(status === 204 ? null : JSON.stringify(body), { status, headers });
}

export function validUuid(value: unknown): value is string {
  return typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}

export function validVersion(value: unknown): value is string {
  return typeof value === "string" && /^[A-Za-z0-9_.-]{1,80}$/.test(value);
}

export async function sha256Hex(value: string): Promise<string> {
  const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(bytes), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function recoverySecretFor(registrationId: string, code: string): Promise<string> {
  const secretKey = Deno.env.get("RECOVERY_HMAC_KEY");
  if (!secretKey || secretKey.length < 32) throw { status: 503, code: "BACKEND_UNCONFIGURED" };
  const key = await crypto.subtle.importKey("raw", new TextEncoder().encode(secretKey),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const bytes = new Uint8Array(await crypto.subtle.sign("HMAC", key,
    new TextEncoder().encode(`${registrationId}:${code}`)));
  return btoa(String.fromCharCode(...bytes)).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/, "");
}

export async function rpc(admin: Admin, name: string, args: Json): Promise<Json> {
  const { data, error } = await admin.rpc(name, args);
  if (error) {
    const status = error.code === "23505" ? 409 : error.code === "28000" ? 403 :
      error.code === "22023" ? 400 : error.code === "P0001" ? 429 : 500;
    throw { status, code: status === 429 ? "RATE_LIMITED" :
      status === 500 ? "BACKEND_ERROR" : "REQUEST_REJECTED" };
  }
  return data as Json;
}

function defaultKey(envName: string): string | undefined {
  try {
    const parsed = JSON.parse(Deno.env.get(envName) || "{}");
    return typeof parsed.default === "string" ? parsed.default : undefined;
  } catch (_) { return undefined; }
}

function serveWithIdentity(handler: Handler, researchAdmin: boolean): void {
  Deno.serve(async (request) => {
    const requestedOrigin = request.headers.get("Origin");
    const allowed = (Deno.env.get("ALLOWED_ORIGINS") || "").split(",").map((item) => item.trim()).filter(Boolean);
    const origin = requestedOrigin && allowed.includes(requestedOrigin) ? requestedOrigin : null;
    if (requestedOrigin && !origin) return response({ error: "ORIGIN_DENIED" }, 403, null);
    if (request.method === "OPTIONS") return response({}, 204, origin);
    if (request.method !== "POST") return response({ error: "METHOD_NOT_ALLOWED" }, 405, origin);
    const authorization = request.headers.get("Authorization") || "";
    const jwt = /^Bearer ([A-Za-z0-9._-]+)$/.exec(authorization)?.[1];
    if (!jwt) return response({ error: "UNAUTHORIZED" }, 401, origin);
    const url = Deno.env.get("SUPABASE_URL");
    const publicKey = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ||
      defaultKey("SUPABASE_PUBLISHABLE_KEYS") || Deno.env.get("SUPABASE_ANON_KEY");
    const serviceKey = Deno.env.get("SUPABASE_SECRET_KEY") ||
      defaultKey("SUPABASE_SECRET_KEYS") || Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !publicKey || !serviceKey) return response({ error: "BACKEND_UNCONFIGURED" }, 503, origin);
    try {
      const auth = createClient(url, publicKey, { auth: { persistSession: false } });
      const { data: identity, error: authError } = await auth.auth.getUser(jwt);
      if (authError || !identity.user || (researchAdmin ?
        identity.user.is_anonymous !== false : identity.user.is_anonymous !== true))
        return response({ error: "UNAUTHORIZED" }, 401, origin);
      const raw = await request.text();
      if (raw.length > 32768) return response({ error: "REQUEST_TOO_LARGE" }, 413, origin);
      const parsed: unknown = JSON.parse(raw);
      if (!parsed || typeof parsed !== "object" || Array.isArray(parsed))
        return response({ error: "INVALID_REQUEST" }, 400, origin);
      const admin = createClient(url, serviceKey, { auth: { persistSession: false } }) as unknown as Admin;
      if (researchAdmin) {
        const { data: permitted, error: permissionError } = await admin.rpc(
          "centinela_research_is_admin", { p_actor: identity.user.id });
        if (permissionError || permitted !== true)
          return response({ error: "ADMIN_REQUIRED" }, 403, origin);
      }
      const result = await handler(parsed as Json, identity.user.id, admin);
      return response(result, 200, origin);
    } catch (error) {
      const typed = error as { status?: number; code?: string };
      const status = typed.status || (error instanceof SyntaxError ? 400 : 500);
      return response({ error: typed.code || (status === 400 ? "INVALID_REQUEST" : "BACKEND_ERROR") }, status, origin);
    }
  });
}

export function serve(handler: Handler): void {
  serveWithIdentity(handler, false);
}

export function serveResearch(handler: Handler): void {
  serveWithIdentity(handler, true);
}
