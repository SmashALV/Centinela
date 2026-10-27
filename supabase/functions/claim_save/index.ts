import { rpc, serve, sha256Hex, validUuid } from "../_shared/endpoint.ts";

serve(async (body, owner, admin) => {
  if (!validUuid(body.save_id) || typeof body.recovery_secret !== "string" ||
      !/^[A-Za-z0-9_-]{43}$/.test(body.recovery_secret))
    throw { status: 400, code: "INVALID_REQUEST" };
  return rpc(admin, "centinela_claim_save", {
    p_owner: owner, p_save_id: body.save_id,
    p_secret_hash: await sha256Hex(body.recovery_secret),
  });
});
