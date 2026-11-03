# P4 · Backend de desarrollo

La extensión P6 para sesiones e informes administrativos se describe en [`../docs/P6_STATUS.md`](../docs/P6_STATUS.md). La función `research_admin` usa una cuenta no anónima permitida explícitamente; las funciones del juego conservan su acceso anónimo. Estas funciones aún no están desplegadas en el proyecto alojado.

La migración crea tablas privadas y cuatro RPC accesibles solo con rol de servicio. Las Edge Functions exigen un JWT de usuario y verifican su identidad antes de llamar esas RPC. La credencial de recuperación sale del servidor y se almacena en IndexedDB separada del snapshot. `CTN-XXXXXX` es solo un código visible; no autoriza recuperación.

La migración `20261031000100_gameplay_telemetry.sql` añade la telemetría descriptiva de juego, la versión `DESCRIPTIVE_ONLY_v1` sin puntaje y las vistas `telemetry_events` y `telemetry_summary`; el catálogo de eventos está en [`../docs/TELEMETRIA_SUPABASE.md`](../docs/TELEMETRIA_SUPABASE.md).

## Preparación local

Se necesita Docker en ejecución y Supabase CLI. Desde la raíz:

```powershell
npx supabase start
Copy-Item supabase/.env.example supabase/.env.local
node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"
npx supabase functions serve --env-file supabase/.env.local
```

Sustituir `RECOVERY_HMAC_KEY` en `.env.local` por el valor aleatorio generado. Mantenerlo estable entre reinicios: una inscripción pendiente usa esa clave para repetir la entrega de su secreto. `ALLOW_TEST_RUBRIC=true` habilita exclusivamente la rúbrica sintética de `seed.sql`; quitarlo en staging/producción. No aplicar `seed.sql` fuera de desarrollo.

La CLI muestra la URL local y la clave pública después de `supabase start`. Copiarlas a `web/backend_config.json` con `rubric_version: "TEST_ONLY_P4_v1"`, poner `enabled: true` y exportar de nuevo la versión Web. La URL y clave publicable del proyecto de desarrollo entregado ya están anotadas allí con `enabled: false`, porque Auth anónima y las funciones todavía no están activas. Esta configuración contiene solo datos publicables; el cliente nunca recibe `service_role`, claves secretas ni `RECOVERY_HMAC_KEY`. `ALLOWED_ORIGINS` debe incluir el origen exacto desde el que se sirve el juego. Para un proyecto de desarrollo alojado, configurar esos secretos en las Edge Functions del proyecto y aplicar la migración únicamente allí.

## Contrato

- `register_save`: recibe `registration_id`, código y versiones. La respuesta entrega `save_id` y una credencial de recuperación. Repetir el mismo `registration_id` produce la misma credencial sin crear otra partida.
- `claim_save`: recupera la partida para una nueva identidad anónima y revoca la anterior.
- `ingest_events`: acepta hasta diez eventos por llamada, devuelve un acuse por evento y respeta secuencias consecutivas. Los eventos educativos se comprueban contra la rúbrica del servidor; los campos de puntuación enviados por el cliente se rechazan.
- `finalize_sync`: declara la última secuencia narrativa. `sync_completed` solo es verdadero cuando se ha recibido esa secuencia y todas las anteriores.

En el cliente, `SyncManager` intenta enviar cada 10 s, reintenta fallos transitorios con retraso creciente y deja en IndexedDB los eventos sin acuse. Los rechazos de validación se detienen para revisión. El resultado del MOBA se guarda de forma atómica con su evento descriptivo cuando hay backend configurado. La vista previa narrativa D0 no genera eventos educativos canónicos.

## Pruebas sin servicio remoto

```powershell
npm ci
npm run test:backend-sql
npm run test:web-storage
npm run test:web-sync
npx deno check --node-modules-dir=auto supabase/functions/register_save/index.ts supabase/functions/claim_save/index.ts supabase/functions/ingest_events/index.ts supabase/functions/finalize_sync/index.ts
```

`test:backend-sql` ejecuta la migración y el seed en PostgreSQL embebido, con identidades sintéticas. `test:web-sync` simula HTTP, Auth, acuses parciales, renovación de token y recuperación. Estas pruebas no sustituyen una prueba contra Supabase de desarrollo: falta ejecutar allí Auth, Edge Functions, CORS y RLS reales. Docker Desktop no estaba activo durante esta implementación.

Cuando el proyecto de desarrollo tenga migración, seed y funciones desplegados, ejecutar la prueba real desde PowerShell con la URL y clave pública de ese proyecto:

```powershell
$env:CENTINELA_TEST_ENV = 'development'
$env:CENTINELA_TEST_URL = 'https://PROJECT_REF.supabase.co'
$env:CENTINELA_TEST_PUBLIC_KEY = 'sb_publishable_...'
npm run test:backend-e2e
```

El script crea dos usuarios Auth anónimos y una partida con rúbrica `TEST_ONLY_P4_v1` en **desarrollo**. Comprueba registro repetido, recuperación, revocación del propietario previo, evento duplicado y finalización. No imprime la credencial de recuperación.

Para el proyecto de desarrollo entregado (`foubkxlhlqxeaywzpebp`), la secuencia preparada tras iniciar sesión en la CLI y activar Auth anónima es:

```powershell
npx supabase link --project-ref foubkxlhlqxeaywzpebp
npx supabase db push --dry-run
npx supabase db push --include-seed
npx supabase secrets set --env-file supabase/.env.local
npx supabase functions deploy
```

Revisar el `--dry-run` antes del `db push`. `--include-seed` es **solo para el proyecto de desarrollo**: carga la rúbrica sintética. `supabase/.env.local` ya se creó en este equipo con una clave HMAC aleatoria y está ignorado por Git; añadir el origen Web real a `ALLOWED_ORIGINS` antes de servir desde otro dominio. Tras desplegar, ejecutar `test:backend-e2e`, cambiar `enabled` a `true` en `web/backend_config.json`, exportar Web y repetir la prueba de navegador. La clave pública sola no autoriza estos comandos.

## Para completar P4

El juego necesita un proyecto Supabase **de desarrollo** y su URL/clave pública para la prueba de extremo a extremo. La rúbrica académica aprobada y los IDs narrativos canónicos siguen ausentes; `TEST_ONLY_P4_v1` nunca representa un puntaje oficial. Deben añadirse reglas de transición narrativa verificadas cuando exista el guion completo. La clave HMAC y la clave de servicio se configuran directamente en el entorno del servidor y no se comparten en el repositorio ni en el chat.
