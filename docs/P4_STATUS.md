# P4 · Estado técnico (27 octubre 2026)

## Implementado

- Migración PostgreSQL con partidas seudónimas, propiedad por identidad Auth, hash de credencial, eventos secuenciales, rúbrica versionada, puntuación solo servidor, límites de peticiones y auditoría de registro/recuperación.
- Edge Functions `register_save`, `claim_save`, `ingest_events` y `finalize_sync` con JWT de usuario anónimo, secreto de servicio solo en servidor y respuestas por evento.
- Cliente Web con Auth anónima, recuperación por credencial local, cola IndexedDB, acuses parciales, reintentos y renovación de sesión. El resultado MOBA puede guardarse con su evento descriptivo en una transacción local.
- Seed `TEST_ONLY_P4_v1` restringido a desarrollo. Los diálogos y decisiones de la vista previa D0 no generan puntuación educativa.

## Evidencia local

| Verificación | Resultado |
|---|---|
| `npm run test:backend-sql` | PASS: permisos, propietario, idempotencia, secuencias, colisión CTN, puntuación y límites |
| `npm run test:web-storage` | PASS: atomicidad, multitab, credenciales y acuses |
| `npm run test:web-sync` | PASS: registro recuperable, reclamo, renovación de Auth y acuses parciales |
| `npx deno check --node-modules-dir=auto ...` | PASS: cuatro Edge Functions |
| Godot 4.4.1 y 4.7.2 headless | PASS: 0 fallos |
| Exportación Web 4.7.2 y `npm run test:browser` | PASS: partida persistida y reabierta, 0 errores de navegador |
| `python tests/verify_recovered_script.py` | PASS: vista previa D0 coincide con fuente recuperada |

## Proyecto Supabase entregado

URL y clave publicable de desarrollo anotadas en `web/backend_config.json`; `enabled: false`. La comprobación remota devolvió Auth anónima desactivada y HTTP 404 para las cuatro funciones. La CLI local indicó que falta `supabase login`. Por ello **P4 no está desplegada ni validada de extremo a extremo**. El usuario indicó que hará después el inicio de sesión CLI y la activación de Auth anónima. Los pasos de despliegue y prueba están en `supabase/README.md`.

No hay repositorio Git inicializado en `E:\GODOT\grooming-2`; por tanto no se creó checkpoint Git. Ningún asset nuevo fue necesario en esta fase; los reemplazos gráficos pendientes siguen especificados en `docs/ASSETS.md`.
