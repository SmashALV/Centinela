import { recoverySecretFor, rpc, serve, sha256Hex, validUuid, validVersion } from "../_shared/endpoint.ts";

serve(async (body, owner, admin) => {
  const code = body.code;
  if (!validUuid(body.registration_id) || typeof code !== "string" || !/^CTN-[0-9]{6}$/.test(code) ||
      !validVersion(body.narrative_version) || !validVersion(body.rubric_version))
    throw { status: 400, code: "INVALID_REQUEST" };
  const recoverySecret = await recoverySecretFor(body.registration_id, code);
  const registered = await rpc(admin, "centinela_register_save", {
    p_owner: owner, p_registration_id: body.registration_id, p_code: code,
    p_narrative_version: body.narrative_version,
    p_rubric_version: body.rubric_version, p_secret_hash: await sha256Hex(recoverySecret),
    p_allow_test: Deno.env.get("ALLOW_TEST_RUBRIC") === "true",
  });
  return { ...registered, recovery_secret: recoverySecret };
});
