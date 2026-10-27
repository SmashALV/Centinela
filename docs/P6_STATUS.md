# P6 · Dashboard de investigación

## Implementado localmente

- Migración `supabase/migrations/20261027000200_p6_research.sql`: administradores permitidos por UUID, sesiones `SES`, asociación manual de códigos `CTN`, clasificación `validated` / `test` / `unvalidated`, auditoría, recibos de rechazo resumidos y versiones de informe inmutables.
- Función `research_admin`: requiere JWT de usuario **no anónimo** y pertenencia activa a `research_admins`. Las tablas privadas mantienen RLS y no conceden acceso directo a `anon` ni `authenticated`.
- Dashboard web separado en `dashboard/`: inicio de sesión administrativo, sesiones y cohortes, versiones de juego/narrativa/rúbrica, cobertura D1–D4, sincronización, rechazos, eventos tardíos, auditoría y exportación de tres datasets en CSV/XLSX.
- La función de ingesta usa el wrapper transaccional `centinela_ingest_events_with_audit`: conserva los rechazos por motivo, secuencia y huella del evento, sin guardar el payload inválido ni datos nominales. Los reintentos incrementan un contador.
- Cada informe se construye en una transacción del servidor y conserva solo partidas `validated`. Las partidas `test` y `unvalidated` quedan fuera de los datasets publicados. Un evento recibido después del cierre requiere `include_late_events: true` y justificación para entrar en una nueva versión; las versiones anteriores permanecen intactas.
- No se guardan credenciales del administrador en `localStorage`, IndexedDB, archivos exportados ni código del cliente. `dashboard/config.json` contiene únicamente URL y clave publicable, con `enabled: false`.

## Verificación realizada

`npm run test:research-sql` prueba permisos, clasificación, exclusión, auditoría, informes inmutables y eventos tardíos con datos sintéticos en PostgreSQL embebido. `npm run test:dashboard-export` comprueba columnas permitidas, neutralización de fórmulas CSV y estructura ZIP XLSX. El XLSX generado también se abrió con `zipfile` de Python y todos sus XML se analizaron. `npm run test:dashboard-browser` prueba autenticación, navegación, informe y descarga XLSX con respuestas simuladas; no accede al proyecto Supabase.

## Conexión posterior al proyecto de desarrollo

Las acciones de P4 que el usuario pospuso siguen pendientes: iniciar sesión en Supabase CLI desde este proyecto y activar **Anonymous Sign-Ins** para el juego. Después, en el proyecto **de desarrollo**:

1. Revisar y aplicar las migraciones P4/P6 **antes** de desplegar las cinco funciones, incluida `research_admin`, porque la ingesta P4 ahora invoca el wrapper de auditoría P6.
2. Crear por el canal administrativo una cuenta de correo/contraseña no anónima aprobada para el equipo investigador. Registrar **solo su UUID** en `centinela_private.research_admins`. No colocar contraseña, `service_role` ni JWT en este repositorio o en el dashboard.
3. Incluir el origen exacto del dashboard en `ALLOWED_ORIGINS` de las Edge Functions y cambiar `dashboard/config.json` a `enabled: true`.
4. Servir `dashboard/` por HTTPS en un origen administrativo separado. Para desarrollo local: `python -m http.server 8001 -d dashboard` y abrir `http://localhost:8001` después de agregar ese origen a `ALLOWED_ORIGINS`.
5. Probar con una cuenta administrativa de desarrollo y partidas sintéticas antes de cualquier dato de investigación.

El dashboard **no está conectado** todavía al proyecto alojado. La rúbrica `TEST_ONLY_P4_v1` es sintética; sus porcentajes no son resultados académicos. El guion canónico y las decisiones evaluables de P5 siguen pendientes, así que el juego actual no produce una cohorte educativa completa.

## Límites restantes de P6

- El dashboard usa una cuenta administrativa permitida por UUID, pero la cuenta compartida aprobada todavía no fue creada ni provisionada en el proyecto de desarrollo.
- Falta la prueba de extremo a extremo contra Supabase de desarrollo y la validación institucional de informes antes de usar datos reales.
