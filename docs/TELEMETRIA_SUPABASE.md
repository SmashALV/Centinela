# Telemetría de juego con Supabase · 31-10-2026

La telemetría registra **hechos de juego sin puntaje, texto libre ni datos personales**. Cada partida se identifica solo por su código `CTN-XXXXXX` y por una identidad anónima de Supabase Auth. Su objetivo es responder a la pregunta de investigación sobre patrones de recorrido y completitud: qué días, escenas y decisiones se jugaron, cuántas pistas se pidieron, cuánta pausa o inactividad hubo y qué final se alcanzó.

## Qué faltaba

La base P4/P6 ya tenía Auth anónima, Edge Functions, cola IndexedDB, reintentos y dashboard, pero:

- **Eventos registrados:** solo se encolaba el resultado del MOBA. Las decisiones de la historia coral, los días, las escenas, las pistas, las pausas, la inactividad y el final no generaban eventos.
- **Fecha rechazada:** el MOBA enviaba `occurred_at` con espacio (`2026-10-31 15:00:00Z`) y el servidor exige `T`. Al activar el backend, ese evento se rechazaba y bloqueaba la sincronización.
- **MOBA diario:** el servidor admitía un resultado MOBA por partida, pero la rutina diaria juega una partida por día. Desde el segundo día se habría producido `result_conflict`.
- **Cierre:** `SyncManager.finalize_story()` existía, pero nunca se llamaba. Por eso `story_completed` y `sync_completed` no podían volverse verdaderos.
- **Rúbrica:** la única versión disponible era la sintética `TEST_ONLY_P4_v1`. Sin `ALLOW_TEST_RUBRIC` no se podía registrar ninguna partida fuera de desarrollo.

## Qué se implementó

| Pieza | Cambio |
|---|---|
| `scripts/Telemetry.gd` | Deriva eventos comparando el último estado guardado con el que se va a guardar: día, escena, elección, acción, pista y final. Solo usa funciones estáticas puras, que se prueban sin escena. |
| `scripts/SaveManager.gd` | `save_slot_async()` adjunta los eventos pendientes al snapshot en **una misma transacción** IndexedDB. `begin_telemetry_session()` registra `session_start` (y `day_start` en una partida nueva); `queue_telemetry()` acumula pausa, inactividad y MOBA local. En escritorio escribe un JSONL por código en `user://telemetry/`. |
| `scripts/SyncManager.gd` | Detecta inactividad de 90 s o más (sin teclado, clic ni mando, fuera de pausa) y la registra al volver. Tras sincronizar, llama a `finalize_story()` cuando la historia tiene final hasta que `sync_completed` sea verdadero. |
| `scripts/Main.gd` | Abre la sesión de telemetría al entrar a una ranura (la vuelta del MOBA continúa la misma sesión) y registra cada pausa. |
| `scripts/moba/MOBAArena.gd` | Corrige el formato ISO 8601 de `occurred_at`. El evento usa el día de la rutina. |
| `web/centinela_storage.js` | `save_event_atomic` acepta `events` (1–10, secuencias consecutivas, `event_id` únicos) además del `event` individual. |
| `supabase/migrations/20261031000100_gameplay_telemetry.sql` | Siete tipos nuevos validados por `valid_telemetry_context`, un MOBA por día, un único final, versión `DESCRIPTIVE_ONLY_v1` sin ítems y las vistas `telemetry_events` y `telemetry_summary`. |
| `web/backend_config.json` | `rubric_version: "DESCRIPTIVE_ONLY_v1"`; `enabled` sigue en `false` hasta desplegar. |

## Catálogo de eventos

Todos comparten `event_id` (UUID v4), `sequence` (consecutiva por partida), `kind`, `narrative_version`, `rubric_version`, `day` (0–4), `scene` (`[A-Za-z0-9_.-]{1,64}`), `occurred_at` (ISO 8601 UTC) y `context`. El servidor rechaza cualquier clave adicional en `context`.

| `kind` | Cuándo | `context` |
|---|---|---|
| `session_start` | Al abrir una ranura | `platform` (`web`/`windows`/`linux`/`macos`), `build`, `resumed` (bool) |
| `day_start` | Partida nueva (D0) y cada vez que cambia el día al dormir | `{}` |
| `scene_start` | Al iniciar una escena coral (`scene` = nodo, p. ej. `D2_A`, `I_TUTOR`) | `{}` |
| `story_choice` | Elección en una de las 10 decisiones coral | `decision_id`, `choice_id` (`A`/`B`/`C`), `behavior` (`protectora`/`limite`/`riesgo`) |
| `story_action` | Acción narrativa relevante | `action`: `D1_LOBBY_DONE`, `TUTOR_INFO_SEEN`, `ADULT_SUPPORT_STARTED`, `DIGITAL_LIMIT_COMPLETED`, `REPAIR_OFFERED`, `SUPPORT_PLANNED`, `LIMIT_PLANNED` |
| `hint_request` | Pedido de pista del día | `level` (`nav`/`h1`/`h2`) |
| `pause` | Al abrir el menú de pausa | `{}` |
| `inactivity` | Al volver tras ≥ 90 s sin entrada | `mode` (`exploration`/`dialogue`/`moba`), `duration_s` |
| `moba_result` | Fin de cada partida MOBA (una por día) | `result` (`victory`/`defeat`/`draw`) |
| `ending_reached` | Al presentar el final | `ending` (`F01`/`F02`/`F03`), `profile` (`protective`/`learning`/`risk`), `protective_choices`, `limit_choices`, `risk_choices` |

`behavior` y `profile` reproducen la **clasificación descriptiva** que el juego ya muestra (`CoralStoryFlow.CHOICE_BEHAVIOR`). No son puntajes ni sustituyen al cuestionario OSAAS. El tipo `decision`, con puntaje de rúbrica en el servidor, sigue reservado para una rúbrica académica aprobada.

Después de `ending_reached` no se emiten más eventos para esa partida. Así, `finalize_sync` puede declarar la última secuencia sin que lleguen eventos posteriores (`after_finalization`).

## Flujo

1. El juego cambia el estado y llama a `SaveManager.save_slot_async()`.
2. `Telemetry.diff()` compara la línea base con el estado nuevo. Los eventos se sellan con UUID, secuencia y fecha.
3. **Web:** IndexedDB guarda snapshot y eventos en una transacción (`event_outbox`). **Escritorio:** el snapshot va a `user://` y los eventos a `user://telemetry/centinela_slot_N_CTN-XXXXXX.jsonl`.
4. `SyncManager` envía la cola cada 10 s a `ingest_events` (máx. 10 por llamada). Los fallos transitorios se reintentan con espera creciente; los rechazos de validación detienen la cola para revisión.
5. PostgreSQL valida y guarda cada evento. Devuelve un acuse por evento y, si alguno se rechaza, lo registra en `ingest_rejections` sin el payload.
6. Al final, `finalize_sync` declara la última secuencia. `sync_completed` pasa a verdadero cuando han llegado todas.

## Análisis

En el SQL Editor del proyecto (rol de servicio):

```sql
-- Una fila por partida: sesiones, último día, elecciones por tipo, pistas, pausas,
-- inactividad, partidas MOBA, final, perfil y completitud.
select * from centinela_private.telemetry_summary order by code;

-- Eventos en orden para reconstruir el recorrido de un participante.
select * from centinela_private.telemetry_events where code = 'CTN-123456' order by sequence;

-- Duración aproximada de cada día: del primer al último evento registrado ese día.
select code, day, round(extract(epoch from max(occurred_at) - min(occurred_at)) / 60, 1) as minutes
from centinela_private.telemetry_events group by code, day order by code, day;
```

`telemetry_complete` es verdadero cuando la partida declaró su final, el servidor recibió todas las secuencias y existe exactamente un `ending_reached`. Es el indicador de **completitud de telemetría** del artículo.

## Desplegar en el proyecto de desarrollo

Requiere iniciar sesión en la CLI de Supabase con la cuenta propietaria y activar **Auth anónima** en el panel (Authentication → Sign In / Providers → Anonymous). Desde la raíz:

```powershell
npx supabase link --project-ref foubkxlhlqxeaywzpebp
npx supabase db push --dry-run
npx supabase db push --include-seed
npx supabase secrets set --env-file supabase/.env.local
npx supabase functions deploy
```

Revisar el `--dry-run`: deben aparecer las tres migraciones. `--include-seed` es solo para desarrollo. Para el estudio, añadir el origen real a `ALLOWED_ORIGINS`, quitar `ALLOW_TEST_RUBRIC` y no aplicar el seed. Después:

1. `npm run test:backend-e2e` con `CENTINELA_TEST_URL` y `CENTINELA_TEST_PUBLIC_KEY`.
2. Poner `"enabled": true` en `web/backend_config.json`.
3. Exportar Web (`Web Development`) y servir desde el origen permitido.
4. Jugar una partida corta y consultar `telemetry_summary`.

## Pruebas

```powershell
npm run test:telemetry-sql   # tipos, contexto estricto, MOBA diario, final único, resumen y sin puntaje
npm run test:web-storage     # lote de eventos atómico, huecos de secuencia y decisiones rechazados
npm run test:backend-sql
npm run test:research-sql
```

`RunTests.tscn` comprueba la derivación de eventos, la línea base, el cierre tras el final, el saneamiento de escenas y el JSONL de escritorio: secuencia, UUID v4 y fecha ISO aceptada por el servidor.

## Límites

- Falta probarlo contra el proyecto Supabase real. Auth, CORS, RLS y Edge Functions solo se verificaron con servicios simulados y PostgreSQL embebido.
- La inactividad en diálogos es aproximada: la lectura avanza sola, así que 90 s sin tocar nada pueden ser lectura atenta. Conviene interpretarla junto con `scene_start`.
- En escritorio no hay envío automático: el investigador debe copiar los JSONL de `%APPDATA%\Godot\app_userdata\Centinela 2.0\telemetry\` al terminar la sesión.
- El dashboard P6 exporta los eventos descriptivos con día, escena y fecha, pero todavía no las columnas de `context` de los tipos nuevos. Para el análisis, usar `telemetry_summary` y `telemetry_events`.
