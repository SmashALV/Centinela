-- P6 research administration. Contains no student names, tokens or seed accounts.
create table centinela_private.research_admins (
  auth_id uuid primary key references auth.users(id),
  active boolean not null default true,
  added_at timestamptz not null default now()
);

create table centinela_private.research_sessions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^SES-[0-9]{3,6}$'),
  state text not null default 'planned' check (state in ('planned', 'in_progress', 'closed')),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  game_version text not null,
  narrative_version text not null,
  rubric_version text not null,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_at > starts_at)
);

create table centinela_private.research_members (
  save_id uuid primary key references centinela_private.participant_saves(id),
  session_id uuid not null references centinela_private.research_sessions(id),
  status text not null default 'unvalidated' check (status in ('unvalidated', 'validated', 'test')),
  reason text not null default '',
  updated_at timestamptz not null default now()
);
create index research_members_session on centinela_private.research_members(session_id);

create table centinela_private.research_audit (
  id bigint generated always as identity primary key,
  session_id uuid references centinela_private.research_sessions(id),
  save_id uuid references centinela_private.participant_saves(id),
  actor_auth_id uuid not null references auth.users(id),
  action text not null,
  detail jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

create table centinela_private.published_reports (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references centinela_private.research_sessions(id),
  version integer not null check (version > 0),
  snapshot jsonb not null,
  justification text not null,
  published_by uuid not null references auth.users(id),
  published_at timestamptz not null default now(),
  unique (session_id, version)
);

create table centinela_private.ingest_rejections (
  save_id uuid not null references centinela_private.participant_saves(id),
  event_fingerprint text not null check (event_fingerprint ~ '^[0-9a-f]{32}$'),
  status text not null,
  sequence integer,
  attempts integer not null default 1 check (attempts > 0),
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  primary key (save_id, event_fingerprint, status)
);

create function centinela_private.reject_research_mutation()
returns trigger language plpgsql set search_path = '' as $$
begin
  raise exception 'published research records are immutable' using errcode = '22023';
end $$;
create trigger immutable_research_audit before update or delete on centinela_private.research_audit
  for each row execute function centinela_private.reject_research_mutation();
create trigger immutable_published_reports before update or delete on centinela_private.published_reports
  for each row execute function centinela_private.reject_research_mutation();

alter table centinela_private.research_admins enable row level security;
alter table centinela_private.research_sessions enable row level security;
alter table centinela_private.research_members enable row level security;
alter table centinela_private.research_audit enable row level security;
alter table centinela_private.published_reports enable row level security;
alter table centinela_private.ingest_rejections enable row level security;
revoke all on centinela_private.research_admins, centinela_private.research_sessions,
  centinela_private.research_members, centinela_private.research_audit,
  centinela_private.published_reports, centinela_private.ingest_rejections
  from public, anon, authenticated;
grant select, insert, update on centinela_private.research_admins,
  centinela_private.research_sessions, centinela_private.research_members to service_role;
grant select, insert on centinela_private.research_audit,
  centinela_private.published_reports to service_role;
grant select, insert, update on centinela_private.ingest_rejections to service_role;
grant usage, select on sequence centinela_private.research_audit_id_seq to service_role;

create function centinela_private.require_research_admin(p_actor uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if p_actor is null or not exists (
    select 1 from centinela_private.research_admins where auth_id = p_actor and active
  ) then
    raise exception 'research administrator required' using errcode = '28000';
  end if;
end $$;

create function public.centinela_ingest_events_with_audit(
  p_owner uuid, p_save_id uuid, p_events jsonb
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_result jsonb;
  v_receipt record;
  v_event jsonb;
  v_status text;
  v_sequence integer;
begin
  v_result := public.centinela_ingest_events(p_owner, p_save_id, p_events);
  for v_receipt in select value, ordinality from
      jsonb_array_elements(v_result->'receipts') with ordinality loop
    v_status := v_receipt.value->>'status';
    if v_status not in ('accepted', 'duplicate') then
      v_event := p_events->(v_receipt.ordinality::integer - 1);
      v_sequence := case when coalesce(v_event->>'sequence', '') ~ '^[1-9][0-9]{0,8}$'
        then (v_event->>'sequence')::integer else null end;
      insert into centinela_private.ingest_rejections
        (save_id, event_fingerprint, status, sequence)
        values (p_save_id, md5(v_event::text), v_status, v_sequence)
        on conflict (save_id, event_fingerprint, status) do update
          set attempts = centinela_private.ingest_rejections.attempts + 1,
              last_seen = now();
    end if;
  end loop;
  return v_result;
end $$;

create function public.centinela_research_is_admin(p_actor uuid)
returns boolean language plpgsql security definer set search_path = '' as $$
begin
  return exists (select 1 from centinela_private.research_admins
    where auth_id = p_actor and active);
end $$;

create function public.centinela_research_command(p_actor uuid, p_action text, p_data jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_session centinela_private.research_sessions;
  v_member centinela_private.research_members;
  v_save centinela_private.participant_saves;
  v_status text;
  v_reason text := trim(coalesce(p_data->>'reason', ''));
  v_snapshot jsonb;
  v_version integer;
  v_report uuid;
  v_issues integer;
  v_late integer;
begin
  perform centinela_private.require_research_admin(p_actor);
  perform centinela_private.consume_rate(p_actor, 'research_command', 30);
  if p_data is null or jsonb_typeof(p_data) <> 'object' then
    raise exception 'invalid command body' using errcode = '22023';
  end if;
  if p_action = 'create_session' then
    if coalesce(p_data->>'code', '') !~ '^SES-[0-9]{3,6}$' or
       coalesce(p_data->>'starts_at', '') !~ '^20[0-9]{2}-[0-9]{2}-[0-9]{2}T' or
       coalesce(p_data->>'ends_at', '') !~ '^20[0-9]{2}-[0-9]{2}-[0-9]{2}T' or
       coalesce(p_data->>'game_version', '') !~ '^[A-Za-z0-9_.-]{1,80}$' or
       coalesce(p_data->>'narrative_version', '') !~ '^[A-Za-z0-9_.-]{1,80}$' or
       coalesce(p_data->>'rubric_version', '') !~ '^[A-Za-z0-9_.-]{1,80}$' then
      raise exception 'invalid session fields' using errcode = '22023';
    end if;
    insert into centinela_private.research_sessions
      (code, starts_at, ends_at, game_version, narrative_version, rubric_version)
      values (p_data->>'code', (p_data->>'starts_at')::timestamptz,
        (p_data->>'ends_at')::timestamptz, p_data->>'game_version',
        p_data->>'narrative_version', p_data->>'rubric_version') returning * into v_session;
    insert into centinela_private.research_audit(session_id, actor_auth_id, action)
      values (v_session.id, p_actor, 'create_session');
    return jsonb_build_object('session_id', v_session.id, 'code', v_session.code);
  elsif p_action = 'set_state' then
    select * into v_session from centinela_private.research_sessions
      where id = (p_data->>'session_id')::uuid for update;
    if not found then raise exception 'session missing' using errcode = '22023'; end if;
    v_status := p_data->>'state';
    if not ((v_session.state = 'planned' and v_status = 'in_progress') or
            (v_session.state = 'in_progress' and v_status = 'closed') or
            (v_session.state = 'closed' and v_status = 'in_progress')) then
      raise exception 'invalid state transition' using errcode = '22023';
    end if;
    if v_session.state = 'closed' and length(v_reason) < 10 then
      raise exception 'reopening requires a reason' using errcode = '22023';
    end if;
    update centinela_private.research_sessions set state = v_status,
      closed_at = case when v_status = 'closed' then now() else null end,
      updated_at = now() where id = v_session.id;
    insert into centinela_private.research_audit(session_id, actor_auth_id, action, detail)
      values (v_session.id, p_actor,
        case when v_session.state = 'closed' then 'reopen_session' else 'set_state' end,
        jsonb_build_object('from', v_session.state, 'to', v_status, 'reason', v_reason));
    return jsonb_build_object('session_id', v_session.id, 'state', v_status);
  elsif p_action = 'associate_save' then
    select * into v_session from centinela_private.research_sessions
      where id = (p_data->>'session_id')::uuid for update;
    if not found or v_session.state = 'closed' then
      raise exception 'session unavailable' using errcode = '22023';
    end if;
    select * into v_save from centinela_private.participant_saves
      where code = p_data->>'code' for update;
    if not found then raise exception 'save missing' using errcode = '22023'; end if;
    if v_save.narrative_version <> v_session.narrative_version or
       v_save.rubric_version <> v_session.rubric_version then
      raise exception 'version mismatch' using errcode = '22023';
    end if;
    insert into centinela_private.research_members(save_id, session_id)
      values (v_save.id, v_session.id);
    insert into centinela_private.research_audit(session_id, save_id, actor_auth_id, action)
      values (v_session.id, v_save.id, p_actor, 'associate_save');
    return jsonb_build_object('save_id', v_save.id, 'code', v_save.code,
      'status', 'unvalidated');
  elsif p_action = 'validate_save' then
    select * into v_member from centinela_private.research_members
      where save_id = (p_data->>'save_id')::uuid for update;
    if not found then raise exception 'save not associated' using errcode = '22023'; end if;
    select * into v_session from centinela_private.research_sessions
      where id = v_member.session_id for update;
    if v_session.state = 'closed' then
      raise exception 'reopen session before validation' using errcode = '22023';
    end if;
    v_status := p_data->>'status';
    if v_status not in ('unvalidated', 'validated', 'test') or length(v_reason) < 3 then
      raise exception 'invalid validation or missing reason' using errcode = '22023';
    end if;
    update centinela_private.research_members set status = v_status,
      reason = left(v_reason, 1000), updated_at = now() where save_id = v_member.save_id;
    insert into centinela_private.research_audit(session_id, save_id, actor_auth_id, action, detail)
      values (v_member.session_id, v_member.save_id, p_actor, 'validate_save',
        jsonb_build_object('from', v_member.status, 'to', v_status, 'reason', v_reason));
    return jsonb_build_object('save_id', v_member.save_id, 'status', v_status);
  elsif p_action = 'publish_report' then
    select * into v_session from centinela_private.research_sessions
      where id = (p_data->>'session_id')::uuid for update;
    if not found or v_session.state <> 'closed' then
      raise exception 'close session before publishing' using errcode = '22023';
    end if;
    select count(*) into v_issues from centinela_private.research_members m
      join centinela_private.participant_saves s on s.id = m.save_id
      where m.session_id = v_session.id and
        (m.status <> 'validated' or not s.story_completed or not s.sync_completed or
         (select g.global_pct from centinela_private.educational_global_scores g
           where g.save_id = s.id) is null or
         exists (select 1 from centinela_private.ingest_rejections ir
           where ir.save_id = s.id) or
         exists (select 1 from centinela_private.game_events e
           where e.save_id = s.id and e.received_at > v_session.closed_at));
    if not exists (select 1 from centinela_private.research_members m
        where m.session_id = v_session.id and m.status = 'validated') then
      v_issues := v_issues + 1;
    end if;
    select count(*) into v_late from centinela_private.research_members m
      join centinela_private.game_events e on e.save_id = m.save_id
      where m.session_id = v_session.id and m.status = 'validated'
        and e.received_at > v_session.closed_at;
    if v_late > 0 and p_data->>'include_late_events' is distinct from 'true' then
      raise exception 'late events require explicit inclusion' using errcode = '22023';
    end if;
    if v_issues > 0 and length(v_reason) < 10 then
      raise exception 'report issues require justification' using errcode = '22023';
    end if;
    select coalesce(max(version), 0) + 1 into v_version
      from centinela_private.published_reports where session_id = v_session.id;
    select jsonb_build_object(
      'schema_version', 1, 'session_code', v_session.code,
      'report_version', v_version, 'state_at_publication', v_session.state,
      'starts_at', v_session.starts_at, 'ends_at', v_session.ends_at,
      'closed_at', v_session.closed_at, 'game_version', v_session.game_version,
      'narrative_version', v_session.narrative_version,
      'rubric_version', v_session.rubric_version,
      'scores', coalesce((select jsonb_agg(jsonb_build_object(
        'code', s.code, 'save_id', s.id, 'story_completed', s.story_completed,
        'sync_completed', s.sync_completed, 'last_sequence', s.last_sequence,
        'declared_sequence', s.declared_sequence, 'narrative_version', s.narrative_version,
        'rubric_version', s.rubric_version, 'global_pct', g.global_pct,
        'rejected_count', (select coalesce(sum(ir.attempts), 0)
          from centinela_private.ingest_rejections ir where ir.save_id = s.id),
        'dimensions', (select coalesce(jsonb_agg(jsonb_build_object(
          'dimension', d.dimension, 'required_items', d.required_items,
          'answered_items', d.answered_items, 'awarded_points', d.awarded_points,
          'score_pct', d.score_pct) order by d.dimension), '[]'::jsonb)
          from centinela_private.educational_scores d where d.save_id = s.id)) order by s.code)
        from centinela_private.research_members m
        join centinela_private.participant_saves s on s.id = m.save_id
        left join centinela_private.educational_global_scores g on g.save_id = s.id
        where m.session_id = v_session.id and m.status = 'validated'), '[]'::jsonb),
      'decisions', coalesce((select jsonb_agg(jsonb_build_object(
        'code', s.code, 'event_id', e.event_id, 'sequence', e.sequence,
        'decision_id', e.decision_id, 'choice_id', e.choice_id,
        'dimension', e.dimension, 'awarded_points', e.awarded_points,
        'rubric_version', s.rubric_version, 'received_at', e.received_at) order by s.code, e.sequence)
        from centinela_private.research_members m
        join centinela_private.participant_saves s on s.id = m.save_id
        join centinela_private.game_events e on e.save_id = s.id and e.kind = 'decision'
        where m.session_id = v_session.id and m.status = 'validated'), '[]'::jsonb),
      'descriptive', coalesce((select jsonb_agg(jsonb_build_object(
        'code', s.code, 'event_id', e.event_id, 'sequence', e.sequence,
        'kind', e.kind, 'day', e.payload->>'day', 'scene', e.payload->>'scene',
        'occurred_at', e.payload->>'occurred_at', 'received_at', e.received_at,
        'result', case when e.kind = 'moba_result' then e.payload #>> '{context,result}' end,
        'mode', case when e.kind = 'inactivity' then e.payload #>> '{context,mode}' end,
        'duration_s', case when e.kind = 'inactivity' then e.payload #>> '{context,duration_s}' end)
        order by s.code, e.sequence)
        from centinela_private.research_members m
        join centinela_private.participant_saves s on s.id = m.save_id
        join centinela_private.game_events e on e.save_id = s.id and e.kind <> 'decision'
        where m.session_id = v_session.id and m.status = 'validated'), '[]'::jsonb),
      'rejections', coalesce((select jsonb_agg(jsonb_build_object(
        'code', q.code, 'status', q.status, 'attempts', q.attempts,
        'last_seen', q.last_seen) order by q.code, q.status)
        from (select s.code, ir.status, sum(ir.attempts) as attempts,
          max(ir.last_seen) as last_seen
          from centinela_private.research_members m
          join centinela_private.participant_saves s on s.id = m.save_id
          join centinela_private.ingest_rejections ir on ir.save_id = s.id
          where m.session_id = v_session.id and m.status = 'validated'
          group by s.code, ir.status) q), '[]'::jsonb),
      'issue_count', v_issues, 'late_event_count', v_late,
      'late_events_included', v_late > 0, 'justification', v_reason)
      into v_snapshot;
    insert into centinela_private.published_reports
      (session_id, version, snapshot, justification, published_by)
      values (v_session.id, v_version, v_snapshot, v_reason, p_actor)
      returning id into v_report;
    insert into centinela_private.research_audit(session_id, actor_auth_id, action, detail)
      values (v_session.id, p_actor, 'publish_report',
        jsonb_build_object('report_id', v_report, 'version', v_version,
          'issue_count', v_issues, 'reason', v_reason));
    return jsonb_build_object('report_id', v_report, 'version', v_version,
      'issue_count', v_issues);
  end if;
  raise exception 'unknown research command' using errcode = '22023';
end $$;

create function public.centinela_research_read(p_actor uuid, p_action text, p_id uuid default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_result jsonb;
begin
  perform centinela_private.require_research_admin(p_actor);
  perform centinela_private.consume_rate(p_actor, 'research_read', 120);
  if p_action = 'overview' then
    select coalesce(jsonb_agg(jsonb_build_object(
      'id', s.id, 'code', s.code, 'state', s.state, 'starts_at', s.starts_at,
      'ends_at', s.ends_at, 'closed_at', s.closed_at,
      'game_version', s.game_version, 'narrative_version', s.narrative_version,
      'rubric_version', s.rubric_version,
      'associated', (select count(*) from centinela_private.research_members m where m.session_id = s.id),
      'validated', (select count(*) from centinela_private.research_members m
        where m.session_id = s.id and m.status = 'validated'),
      'covered', (select count(g.global_pct) from centinela_private.research_members m
        join centinela_private.educational_global_scores g on g.save_id = m.save_id
        where m.session_id = s.id and m.status = 'validated'),
      'avg_global_pct', (select round(avg(g.global_pct), 2)
        from centinela_private.research_members m
        join centinela_private.educational_global_scores g on g.save_id = m.save_id
        where m.session_id = s.id and m.status = 'validated'),
      'latest_report', (select max(r.version) from centinela_private.published_reports r
        where r.session_id = s.id)) order by s.code), '[]'::jsonb)
      into v_result from centinela_private.research_sessions s;
    return jsonb_build_object('sessions', v_result);
  elsif p_action = 'session' then
    if not exists (select 1 from centinela_private.research_sessions where id = p_id) then
      raise exception 'session missing' using errcode = '22023';
    end if;
    select jsonb_build_object(
      'session', (select to_jsonb(s) from centinela_private.research_sessions s where s.id = p_id),
      'members', coalesce((select jsonb_agg(jsonb_build_object(
        'save_id', m.save_id, 'code', s.code, 'status', m.status, 'reason', m.reason,
        'story_completed', s.story_completed, 'sync_completed', s.sync_completed,
        'last_sequence', s.last_sequence, 'declared_sequence', s.declared_sequence,
        'global_pct', g.global_pct, 'rubric_version', s.rubric_version,
        'late_events', (select count(*) from centinela_private.game_events e
          join centinela_private.research_sessions rs on rs.id = m.session_id
          where e.save_id = s.id and rs.closed_at is not null and e.received_at > rs.closed_at),
        'rejected_count', (select coalesce(sum(ir.attempts), 0)
          from centinela_private.ingest_rejections ir where ir.save_id = s.id),
        'rejection_statuses', (select coalesce(jsonb_agg(jsonb_build_object(
          'status', q.status, 'attempts', q.attempts) order by q.status), '[]'::jsonb)
          from (select ir.status, sum(ir.attempts) as attempts
            from centinela_private.ingest_rejections ir where ir.save_id = s.id
            group by ir.status) q),
        'dimensions', (select coalesce(jsonb_agg(jsonb_build_object(
          'dimension', d.dimension, 'answered_items', d.answered_items,
          'required_items', d.required_items, 'score_pct', d.score_pct)
          order by d.dimension), '[]'::jsonb)
          from centinela_private.educational_scores d where d.save_id = s.id)) order by s.code)
        from centinela_private.research_members m
        join centinela_private.participant_saves s on s.id = m.save_id
        left join centinela_private.educational_global_scores g on g.save_id = s.id
        where m.session_id = p_id), '[]'::jsonb),
      'reports', coalesce((select jsonb_agg(jsonb_build_object(
        'id', r.id, 'version', r.version, 'published_at', r.published_at,
        'issue_count', r.snapshot->'issue_count') order by r.version)
        from centinela_private.published_reports r where r.session_id = p_id), '[]'::jsonb),
      'audit', coalesce((select jsonb_agg(jsonb_build_object(
        'action', a.action, 'detail', a.detail, 'occurred_at', a.occurred_at)
        order by a.id desc) from centinela_private.research_audit a
        where a.session_id = p_id), '[]'::jsonb)) into v_result;
    return v_result;
  elsif p_action = 'report' then
    select jsonb_build_object('id', r.id, 'version', r.version,
      'published_at', r.published_at, 'snapshot', r.snapshot)
      into v_result from centinela_private.published_reports r where r.id = p_id;
    if v_result is null then raise exception 'report missing' using errcode = '22023'; end if;
    return v_result;
  end if;
  raise exception 'unknown research read' using errcode = '22023';
end $$;

revoke all on function public.centinela_research_is_admin(uuid) from public, anon, authenticated;
revoke all on function public.centinela_ingest_events_with_audit(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.centinela_research_command(uuid, text, jsonb) from public, anon, authenticated;
revoke all on function public.centinela_research_read(uuid, text, uuid) from public, anon, authenticated;
grant execute on function public.centinela_research_is_admin(uuid) to service_role;
grant execute on function public.centinela_ingest_events_with_audit(uuid, uuid, jsonb) to service_role;
grant execute on function public.centinela_research_command(uuid, text, jsonb) to service_role;
grant execute on function public.centinela_research_read(uuid, text, uuid) to service_role;
