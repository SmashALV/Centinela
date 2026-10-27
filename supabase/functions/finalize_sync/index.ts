import { rpc, serve, validUuid } from "../_shared/endpoint.ts";

serve(async (body, owner, admin) => {
  if (!validUuid(body.save_id) || !Number.isSafeInteger(body.last_sequence) ||
      (body.last_sequence as number) < 0)
    throw { status: 400, code: "INVALID_REQUEST" };
  return rpc(admin, "centinela_finalize_sync", {
    p_owner: owner, p_save_id: body.save_id, p_last_sequence: body.last_sequence,
  });
});
