-- P4 foundation. No rubric or participant data is inserted by this migration.
create schema if not exists centinela_private;
revoke all on schema centinela_private from public, anon, authenticated;
grant usage on schema centinela_private to service_role;

create table centinela_private.rubric_versions (
  version text primary key,
  narrative_version text not null,
  active boolean not null default false,
  development_only boolean not null default false,
  created_at timestamptz not null default now()
);

create table centinela_private.rubric_items (
  rubric_version text not null references centinela_private.rubric_versions(version),
  decision_id text not null,
  choice_id text not null,
  dimension text not null check (dimension in ('D1', 'D2', 'D3', 'D4')),
  points smallint not null check (points between 0 and 2),
  primary key (rubric_version, decision_id, choice_id)
);

create table centinela_private.rubric_requirements (
  rubric_version text not null references centinela_private.rubric_versions(version),
  dimension text not null check (dimension in ('D1', 'D2', 'D3', 'D4')),
  required_items integer not null check (required_items > 0),
  primary key (rubric_version, dimension)
);

create table centinela_private.participant_saves (
  id uuid primary key default gen_random_uuid(),
  registration_id uuid not null unique,
  requested_code text not null check (requested_code ~ '^CTN-[0-9]{6}$'),
  code text not null unique check (code ~ '^CTN-[0-9]{6}$'),
  owner_auth_id uuid not null references auth.users(id),
  secret_hash text not null check (secret_hash ~ '^[0-9a-f]{64}$'),
  narrative_version text not null,
  rubric_version text not null references centinela_private.rubric_versions(version),
  last_sequence integer not null default 0 check (last_sequence >= 0),
  declared_sequence integer check (declared_sequence >= 0),
  story_completed boolean not null default false,
  sync_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table centinela_private.game_events (
  event_id uuid primary key,
  save_id uuid not null references centinela_private.participant_saves(id),
  sequence integer not null check (sequence > 0),
  kind text not null check (kind in ('decision', 'moba_result', 'pause', 'inactivity')),
  payload jsonb not null,
  decision_id text,
  choice_id text,
  dimension text check (dimension in ('D1', 'D2', 'D3', 'D4')),
  awarded_points smallint check (awarded_points between 0 and 2),
  received_at timestamptz not null default now(),
  unique (save_id, sequence)
);
create index game_events_save_sequence on centinela_private.game_events(save_id, sequence);
create unique index game_events_one_decision on centinela_private.game_events(save_id, decision_id)
  where kind = 'decision';
create unique index game_events_one_moba_result on centinela_private.game_events(save_id)
  where kind = 'moba_result';

create table centinela_private.audit_events (
  id bigint generated always as identity primary key,
  save_id uuid references centinela_private.participant_saves(id),
  action text not null,
  actor_auth_id uuid,
  occurred_at timestamptz not null default now()
);

create table centinela_private.request_limits (
  owner_auth_id uuid not null references auth.users(id) on delete cascade,
  operation text not null,
  window_start timestamptz not null,
  requests integer not null,
  primary key (owner_auth_id, operation)
);

create function centinela_private.consume_rate(p_owner uuid, p_operation text, p_limit integer)
returns void language plpgsql set search_path = '' as $$
declare v_requests integer;
begin
  insert into centinela_private.request_limits(owner_auth_id, operation, window_start, requests)
    values (p_owner, p_operation, date_trunc('minute', now()), 1)
    on conflict (owner_auth_id, operation) do update
      set requests = case when centinela_private.request_limits.window_start < date_trunc('minute', now())
        then 1 else centinela_private.request_limits.requests + 1 end,
      window_start = date_trunc('minute', now())
    returning requests into v_requests;
  if v_requests > p_limit then
    raise exception 'rate limit' using errcode = 'P0001';
  end if;
end $$;

create function centinela_private.prevent_used_rubric_change()
returns trigger language plpgsql set search_path = '' as $$
declare v_version text;
begin
  v_version := coalesce(to_jsonb(new)->>'rubric_version', to_jsonb(old)->>'rubric_version',
    to_jsonb(old)->>'version');
  if exists (select 1 from centinela_private.participant_saves where rubric_version = v_version) then
    raise exception 'rubric version already used by a save' using errcode = '22023';
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end $$;
create trigger freeze_rubric_version before update or delete on centinela_private.rubric_versions
  for each row execute function centinela_private.prevent_used_rubric_change();
create trigger freeze_rubric_items before insert or update or delete on centinela_private.rubric_items
  for each row execute function centinela_private.prevent_used_rubric_change();
create trigger freeze_rubric_requirements before insert or update or delete on centinela_private.rubric_requirements
  for each row execute function centinela_private.prevent_used_rubric_change();

alter table centinela_private.rubric_versions enable row level security;
alter table centinela_private.rubric_items enable row level security;
alter table centinela_private.rubric_requirements enable row level security;
alter table centinela_private.participant_saves enable row level security;
alter table centinela_private.game_events enable row level security;
alter table centinela_private.audit_events enable row level security;
alter table centinela_private.request_limits enable row level security;
revoke all on all tables in schema centinela_private from public, anon, authenticated;
grant select, insert, update on all tables in schema centinela_private to service_role;
grant usage, select on all sequences in schema centinela_private to service_role;

create function public.centinela_register_save(
  p_owner uuid, p_registration_id uuid, p_code text, p_narrative_version text,
  p_rubric_version text, p_secret_hash text, p_allow_test boolean
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_save centinela_private.participant_saves;
  v_code text;
  v_attempt integer;
begin
  if p_registration_id is null or p_code !~ '^CTN-[0-9]{6}$' or p_secret_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid registration' using errcode = '22023';
  end if;
  if not exists (select 1 from centinela_private.rubric_versions
      where version = p_rubric_version and narrative_version = p_narrative_version and active
        and (not development_only or p_allow_test is true)) then
    raise exception 'rubric unavailable' using errcode = '22023';
  end if;
  perform centinela_private.consume_rate(p_owner, 'register', 20);
  perform pg_catalog.pg_advisory_xact_lock(204271027::bigint);
  select * into v_save from centinela_private.participant_saves
    where registration_id = p_registration_id for update;
  if found then
    if v_save.requested_code <> p_code or v_save.narrative_version <> p_narrative_version or
       v_save.rubric_version <> p_rubric_version or v_save.secret_hash <> p_secret_hash then
      raise exception 'registration id reused with different data' using errcode = '22023';
    end if;
    update centinela_private.participant_saves set owner_auth_id = p_owner, updated_at = now()
      where id = v_save.id;
    insert into centinela_private.audit_events(save_id, action, actor_auth_id)
      values (v_save.id, 'register_retry', p_owner);
    return jsonb_build_object('save_id', v_save.id, 'code', v_save.code);
  end if;
  v_code := p_code;
  for v_attempt in 1..25 loop
    if not exists (select 1 from centinela_private.participant_saves where code = v_code) then
      insert into centinela_private.participant_saves
        (registration_id, requested_code, code, owner_auth_id, secret_hash, narrative_version, rubric_version)
        values (p_registration_id, p_code, v_code, p_owner, p_secret_hash, p_narrative_version, p_rubric_version)
        returning * into v_save;
      exit;
    end if;
    v_code := 'CTN-' || lpad((floor(random() * 1000000)::integer)::text, 6, '0');
  end loop;
  if v_save.id is null then
    raise exception 'code space exhausted' using errcode = '23505';
  end if;
  insert into centinela_private.audit_events(save_id, action, actor_auth_id)
    values (v_save.id, 'register', p_owner);
  return jsonb_build_object('save_id', v_save.id, 'code', v_save.code);
end $$;

create function public.centinela_claim_save(
  p_owner uuid, p_save_id uuid, p_secret_hash text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_save centinela_private.participant_saves;
begin
  perform centinela_private.consume_rate(p_owner, 'claim', 20);
  select * into v_save from centinela_private.participant_saves
    where id = p_save_id for update;
  if not found or v_save.secret_hash <> p_secret_hash then
    raise exception 'invalid recovery credential' using errcode = '28000';
  end if;
  update centinela_private.participant_saves set owner_auth_id = p_owner, updated_at = now()
    where id = p_save_id;
  insert into centinela_private.audit_events(save_id, action, actor_auth_id)
    values (p_save_id, 'claim', p_owner);
  return jsonb_build_object('save_id', p_save_id, 'code', v_save.code,
    'last_sequence', v_save.last_sequence,
    'story_completed', v_save.story_completed, 'sync_completed', v_save.sync_completed);
end $$;

create function public.centinela_ingest_events(
  p_owner uuid, p_save_id uuid, p_events jsonb
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_save centinela_private.participant_saves;
  v_event jsonb;
  v_existing centinela_private.game_events;
  v_id uuid;
  v_sequence integer;
  v_kind text;
  v_dim text;
  v_points smallint;
  v_receipts jsonb := '[]'::jsonb;
  v_status text;
begin
  if jsonb_typeof(p_events) <> 'array' or jsonb_array_length(p_events) not between 1 and 10 then
    raise exception 'batch size must be 1..10' using errcode = '22023';
  end if;
  perform centinela_private.consume_rate(p_owner, 'ingest', 60);
  select * into v_save from centinela_private.participant_saves
    where id = p_save_id for update;
  if not found or v_save.owner_auth_id <> p_owner then
    raise exception 'save owner changed' using errcode = '28000';
  end if;
  for v_event in select value from jsonb_array_elements(p_events) loop
    v_status := null;
    v_dim := null;
    v_points := null;
    if jsonb_typeof(v_event) <> 'object' or
       coalesce(v_event->>'event_id', '') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' or
       coalesce(v_event->>'sequence', '') !~ '^[1-9][0-9]{0,8}$' then
      v_receipts := v_receipts || jsonb_build_array(jsonb_build_object('event_id', v_event->>'event_id', 'status', 'invalid_event'));
      continue;
    end if;
    if exists (select 1 from jsonb_object_keys(v_event) as key_name
        where key_name not in ('event_id', 'sequence', 'kind', 'narrative_version',
          'rubric_version', 'day', 'scene', 'occurred_at', 'context', 'decision_id', 'choice_id')) or
       coalesce(v_event->>'day', '') !~ '^[0-4]$' or
       coalesce(v_event->>'scene', '') !~ '^[A-Za-z0-9_.-]{1,64}$' or
       coalesce(v_event->>'occurred_at', '') !~ '^20[0-9]{2}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}([.][0-9]{1,3})?(Z|[+-][0-9]{2}:[0-9]{2})$' or
       jsonb_typeof(v_event->'context') is distinct from 'object' then
      v_receipts := v_receipts || jsonb_build_array(jsonb_build_object('event_id', v_event->>'event_id', 'status', 'invalid_event'));
      continue;
    end if;
    v_id := (v_event->>'event_id')::uuid;
    v_sequence := (v_event->>'sequence')::integer;
    v_kind := v_event->>'kind';
    select * into v_existing from centinela_private.game_events where event_id = v_id;
    if found then
      v_status := case when v_existing.save_id = p_save_id and v_existing.sequence = v_sequence
        and v_existing.payload = v_event then 'duplicate' else 'event_id_conflict' end;
    elsif v_sequence <= v_save.last_sequence then
      v_status := 'sequence_conflict';
    elsif v_sequence <> v_save.last_sequence + 1 then
      v_status := 'missing_sequence';
    elsif v_save.story_completed and v_sequence > v_save.declared_sequence then
      v_status := 'after_finalization';
    elsif v_event->>'narrative_version' is distinct from v_save.narrative_version or
          v_event->>'rubric_version' is distinct from v_save.rubric_version then
      v_status := 'version_mismatch';
    elsif v_kind <> 'decision' and (v_event ? 'decision_id' or v_event ? 'choice_id') then
      v_status := 'invalid_event';
    elsif v_kind = 'decision' then
      if coalesce(v_event->>'decision_id', '') !~ '^[A-Za-z0-9_.-]{1,80}$' or
         coalesce(v_event->>'choice_id', '') !~ '^[A-Za-z0-9_.-]{1,80}$' or
         v_event->'context' <> '{}'::jsonb then
        v_status := 'invalid_event';
      elsif exists (select 1 from centinela_private.game_events
          where save_id = p_save_id and decision_id = v_event->>'decision_id') then
        v_status := 'decision_conflict';
      else
        select dimension, points into v_dim, v_points from centinela_private.rubric_items
          where rubric_version = v_save.rubric_version and decision_id = v_event->>'decision_id'
            and choice_id = v_event->>'choice_id';
        if not found then v_status := 'unknown_choice'; end if;
      end if;
    elsif v_kind = 'moba_result' then
      if v_event ? 'decision_id' or v_event ? 'choice_id' or
         v_event->'context' is distinct from jsonb_build_object('result', v_event #>> '{context,result}') or
         coalesce(v_event #>> '{context,result}', '') not in ('victory', 'defeat', 'draw') then
        v_status := 'invalid_event';
      elsif exists (select 1 from centinela_private.game_events
          where save_id = p_save_id and kind = 'moba_result') then
        v_status := 'result_conflict';
      end if;
    elsif v_kind = 'pause' then
      if coalesce(v_event->'context', '{}'::jsonb) <> '{}'::jsonb then v_status := 'invalid_event'; end if;
    elsif v_kind = 'inactivity' then
      if coalesce(v_event #>> '{context,mode}', '') not in ('exploration', 'dialogue', 'moba') or
         coalesce(v_event #>> '{context,duration_s}', '') !~ '^[1-9][0-9]{0,5}$' or
         v_event->'context' is distinct from jsonb_build_object('mode', v_event #>> '{context,mode}',
           'duration_s', v_event #> '{context,duration_s}') then
        v_status := 'invalid_event';
      end if;
    else
      v_status := 'invalid_event';
    end if;
    if v_status is null then
      insert into centinela_private.game_events
        (event_id, save_id, sequence, kind, payload, decision_id, choice_id, dimension, awarded_points)
        values (v_id, p_save_id, v_sequence, v_kind, v_event,
          case when v_kind = 'decision' then v_event->>'decision_id' else null end,
          case when v_kind = 'decision' then v_event->>'choice_id' else null end,
          v_dim, v_points);
      v_save.last_sequence := v_sequence;
      v_status := 'accepted';
    end if;
    v_receipts := v_receipts || jsonb_build_array(jsonb_build_object('event_id', v_event->>'event_id', 'status', v_status));
  end loop;
  update centinela_private.participant_saves set last_sequence = v_save.last_sequence,
    sync_completed = story_completed and declared_sequence = v_save.last_sequence,
    updated_at = now() where id = p_save_id;
  return jsonb_build_object('receipts', v_receipts, 'last_sequence', v_save.last_sequence,
    'sync_completed', v_save.story_completed and v_save.declared_sequence = v_save.last_sequence);
end $$;

create function public.centinela_finalize_sync(
  p_owner uuid, p_save_id uuid, p_last_sequence integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_save centinela_private.participant_saves;
begin
  perform centinela_private.consume_rate(p_owner, 'finalize', 20);
  select * into v_save from centinela_private.participant_saves where id = p_save_id for update;
  if not found or v_save.owner_auth_id <> p_owner then
    raise exception 'save owner changed' using errcode = '28000';
  end if;
  if p_last_sequence is null or p_last_sequence < v_save.last_sequence or
     (v_save.story_completed and p_last_sequence <> v_save.declared_sequence) then
    raise exception 'invalid declared sequence' using errcode = '22023';
  end if;
  update centinela_private.participant_saves set story_completed = true,
    declared_sequence = p_last_sequence, sync_completed = (last_sequence = p_last_sequence),
    updated_at = now() where id = p_save_id;
  return jsonb_build_object('story_completed', true,
    'sync_completed', v_save.last_sequence = p_last_sequence,
    'last_sequence', v_save.last_sequence, 'declared_sequence', p_last_sequence);
end $$;

create view centinela_private.educational_scores as
select s.id as save_id, r.dimension, r.required_items,
  count(e.event_id)::integer as answered_items,
  coalesce(sum(e.awarded_points), 0)::integer as awarded_points,
  case when count(e.event_id) >= r.required_items then
    round(100.0 * sum(e.awarded_points) / (2 * count(e.event_id)), 2) else null end as score_pct
from centinela_private.participant_saves s
join centinela_private.rubric_requirements r on r.rubric_version = s.rubric_version
left join centinela_private.game_events e on e.save_id = s.id and e.dimension = r.dimension
group by s.id, r.dimension, r.required_items;

create view centinela_private.educational_global_scores as
select save_id,
  case when count(*) = 4 and count(score_pct) = 4 then round(avg(score_pct), 2) else null end as global_pct
from centinela_private.educational_scores group by save_id;

revoke all on function public.centinela_register_save(uuid, uuid, text, text, text, text, boolean) from public, anon, authenticated;
revoke all on function public.centinela_claim_save(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.centinela_ingest_events(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.centinela_finalize_sync(uuid, uuid, integer) from public, anon, authenticated;
grant execute on function public.centinela_register_save(uuid, uuid, text, text, text, text, boolean) to service_role;
grant execute on function public.centinela_claim_save(uuid, uuid, text) to service_role;
grant execute on function public.centinela_ingest_events(uuid, uuid, jsonb) to service_role;
grant execute on function public.centinela_finalize_sync(uuid, uuid, integer) to service_role;
revoke all on centinela_private.educational_scores, centinela_private.educational_global_scores from public, anon, authenticated;
grant select on centinela_private.educational_scores, centinela_private.educational_global_scores to service_role;
