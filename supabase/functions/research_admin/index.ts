import { rpc, serveResearch, validUuid } from "../_shared/endpoint.ts";

const READ_ACTIONS = new Set(["overview", "session", "report"]);
const COMMAND_ACTIONS = new Set([
  "create_session", "set_state", "associate_save", "validate_save", "publish_report"
]);

serveResearch(async (body, actor, admin) => {
  const action = body.action;
  if (typeof action !== "string") throw { status: 400, code: "INVALID_REQUEST" };
  if (READ_ACTIONS.has(action)) {
    const id = body.id;
    if (action !== "overview" && !validUuid(id))
      throw { status: 400, code: "INVALID_REQUEST" };
    if (action === "overview" && id != null)
      throw { status: 400, code: "INVALID_REQUEST" };
    return await rpc(admin, "centinela_research_read", {
      p_actor: actor, p_action: action, p_id: id ?? null
    });
  }
  if (COMMAND_ACTIONS.has(action)) {
    const data = body.data;
    if (!data || typeof data !== "object" || Array.isArray(data))
      throw { status: 400, code: "INVALID_REQUEST" };
    const fields = data as Record<string, unknown>;
    if (["set_state", "associate_save", "publish_report"].includes(action) &&
        !validUuid(fields.session_id))
      throw { status: 400, code: "INVALID_REQUEST" };
    if (action === "validate_save" && !validUuid(fields.save_id))
      throw { status: 400, code: "INVALID_REQUEST" };
    if (action === "associate_save" &&
        (typeof fields.code !== "string" || !/^CTN-[0-9]{6}$/.test(fields.code)))
      throw { status: 400, code: "INVALID_REQUEST" };
    if (action === "publish_report" && fields.include_late_events != null &&
        typeof fields.include_late_events !== "boolean")
      throw { status: 400, code: "INVALID_REQUEST" };
    return await rpc(admin, "centinela_research_command", {
      p_actor: actor, p_action: action, p_data: data
    });
  }
  throw { status: 400, code: "INVALID_REQUEST" };
});
