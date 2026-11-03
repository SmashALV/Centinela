-- Telemetría descriptiva de juego. No inserta datos de participantes ni asigna puntaje:
-- registra hechos (inicio de sesión, días, escenas, elecciones con su clasificación
-- descriptiva, acciones, pistas y final) para analizar recorridos y completitud.

alter table centinela_private.game_events drop constraint game_events_kind_check;
alter table centinela_private.game_events add constraint game_events_kind_check check (kind in (
  'decision', 'moba_result', 'pause', 'inactivity', 'session_start', 'day_start', 'scene_start',
  'story_choice', 'story_action', 'hint_request', 'ending_reached'));

-- La rutina diaria permite una partida MOBA por día (D0–D4), no una por guardado.
drop index centinela_private.game_events_one_moba_result;
create unique index game_events_one_moba_per_day on centinela_private.game_events(save_id, (payload->>'day'))
  where kind = 'moba_result';
create unique index game_events_one_ending on centinela_private.game_events(save_id)
  where kind = 'ending_reached';

-- Versión sin ítems ni requisitos: permite registrar partidas en staging o producción
-- sin activar la rúbrica sintética ni calcular puntajes educativos.
insert into centinela_private.rubric_versions(version, narrative_version, active, development_only)
values ('DESCRIPTIVE_ONLY_v1', 'provisional-d0-1', true, false)
on conflict (version) do nothing;

-- Cada tipo acepta exactamente sus claves; ningún campo admite texto libre.
create function centinela_private.valid_telemetry_context(p_kind text, p_context jsonb)
returns boolean language sql immutable set search_path = '' as $$
  select case p_kind
    when 'session_start' then
      p_context = jsonb_build_object('platform', p_context->'platform', 'build', p_context->'build',
        'resumed', p_context->'resumed') and
      coalesce(p_context->>'platform', '') in ('web', 'windows', 'linux', 'macos') and
      coalesce(p_context->>'build', '') ~ '^[A-Za-z0-9_.-]{1,40}$' and
      jsonb_typeof(p_context->'resumed') = 'boolean'
    when 'day_start' then p_context = '{}'::jsonb
    when 'scene_start' then p_context = '{}'::jsonb
    when 'story_choice' then
      p_context = jsonb_build_object('decision_id', p_context->'decision_id',
        'choice_id', p_context->'choice_id', 'behavior', p_context->'behavior') and
      coalesce(p_context->>'decision_id', '') ~ '^[A-Z0-9_]{1,40}$' and
      coalesce(p_context->>'choice_id', '') in ('A', 'B', 'C') and
      coalesce(p_context->>'behavior', '') in ('protectora', 'limite', 'riesgo')
    when 'story_action' then
      p_context = jsonb_build_object('action', p_context->'action') and
      coalesce(p_context->>'action', '') ~ '^[A-Z0-9_]{1,48}$'
    when 'hint_request' then
      p_context = jsonb_build_object('level', p_context->'level') and
      coalesce(p_context->>'level', '') in ('nav', 'h1', 'h2')
    when 'ending_reached' then
      p_context = jsonb_build_object('ending', p_context->'ending', 'profile', p_context->'profile',
        'protective_choices', p_context->'protective_choices', 'limit_choices', p_context->'limit_choices',
        'risk_choices', p_context->'risk_choices') and
      coalesce(p_context->>'ending', '') in ('F01', 'F02', 'F03') and
      coalesce(p_context->>'profile', '') in ('protective', 'learning', 'risk') and
      coalesce(p_context->>'protective_choices', '') ~ '^[0-9]{1,2}$' and
      coalesce(p_context->>'limit_choices', '') ~ '^[0-9]{1,2}$' and
      coalesce(p_context->>'risk_choices', '') ~ '^[0-9]{1,2}$'
    else false
  end
$$;
revoke all on function centinela_private.valid_telemetry_context(text, jsonb) from public, anon, authenticated;

create or replace function public.centinela_ingest_events(
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
          where save_id = p_save_id and kind = 'moba_result' and payload->>'day' = v_event->>'day') then
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
    elsif v_kind in ('session_start', 'day_start', 'scene_start', 'story_choice',
        'story_action', 'hint_request', 'ending_reached') then
      if centinela_private.valid_telemetry_context(v_kind, v_event->'context') is not true then
        v_status := 'invalid_event';
      elsif v_kind = 'ending_reached' and exists (select 1 from centinela_private.game_events
          where save_id = p_save_id and kind = 'ending_reached') then
        v_status := 'result_conflict';
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

-- Vistas para el análisis (solo rol de servicio: SQL Editor o exportación del investigador).
create view centinela_private.telemetry_events as
select s.code, e.save_id, e.sequence, e.kind, (e.payload->>'day')::integer as day,
  e.payload->>'scene' as scene, (e.payload->>'occurred_at')::timestamptz as occurred_at,
  e.received_at, e.payload->'context' as context
from centinela_private.game_events e
join centinela_private.participant_saves s on s.id = e.save_id;

create view centinela_private.telemetry_summary as
select s.code, s.id as save_id, s.narrative_version, s.rubric_version,
  min(t.occurred_at) as first_event_at, max(t.occurred_at) as last_event_at,
  count(*) filter (where t.kind = 'session_start')::integer as sessions,
  coalesce(max(t.day) filter (where t.kind = 'day_start'), 0) as last_day_started,
  count(*) filter (where t.kind = 'scene_start')::integer as scenes_started,
  count(*) filter (where t.kind = 'story_choice')::integer as choices,
  count(*) filter (where t.kind = 'story_choice' and t.context->>'behavior' = 'protectora')::integer as protective_choices,
  count(*) filter (where t.kind = 'story_choice' and t.context->>'behavior' = 'limite')::integer as limit_choices,
  count(*) filter (where t.kind = 'story_choice' and t.context->>'behavior' = 'riesgo')::integer as risk_choices,
  count(*) filter (where t.kind = 'hint_request')::integer as hints,
  count(*) filter (where t.kind = 'pause')::integer as pauses,
  coalesce(sum((t.context->>'duration_s')::integer) filter (where t.kind = 'inactivity'), 0)::integer as inactive_seconds,
  count(*) filter (where t.kind = 'moba_result')::integer as moba_matches,
  max(t.context->>'ending') filter (where t.kind = 'ending_reached') as ending,
  max(t.context->>'profile') filter (where t.kind = 'ending_reached') as profile,
  s.last_sequence, s.story_completed, s.sync_completed,
  (s.story_completed and s.sync_completed and
    count(*) filter (where t.kind = 'ending_reached') = 1) as telemetry_complete
from centinela_private.participant_saves s
left join centinela_private.telemetry_events t on t.save_id = s.id
group by s.id;

revoke all on centinela_private.telemetry_events, centinela_private.telemetry_summary from public, anon, authenticated;
grant select on centinela_private.telemetry_events, centinela_private.telemetry_summary to service_role;
