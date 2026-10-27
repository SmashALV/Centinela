import { rpc, serve, validUuid } from "../_shared/endpoint.ts";

serve(async (body, owner, admin) => {
  if (!validUuid(body.save_id) || !Array.isArray(body.events) ||
      body.events.length < 1 || body.events.length > 10)
    throw { status: 400, code: "INVALID_REQUEST" };
  return rpc(admin, "centinela_ingest_events_with_audit", {
    p_owner: owner, p_save_id: body.save_id, p_events: body.events,
  });
});
