# Cierre técnico y requisitos no funcionales · 0.32.1-preview

Este registro evalúa el prototipo local. Un PASS local acredita solo la prueba indicada; no equivale a aprobación de contenido, despliegue o eficacia educativa.

**Ejecución del 28-10-2026:** Godot 4.7.2 `RunTests.tscn` terminó con 0 fallos; `StoryRoutesTests.tscn` pasó las tres rutas en Godot 4.4.1 y 4.7.2; `npm run test:browser` pasó en Chrome y Edge sin errores de navegador; `test:web-storage`, `test:web-sync` y nueve pruebas de `test_release.py` pasaron. Se usaron datos sintéticos y el backend real permaneció desactivado.

| Requisito del GDD | Evidencia actual | Estado para entrega |
|---|---|---|
| Fiabilidad y continuidad | `tests/StoryRoutesTests.tscn` parte del resultado guardado del MOBA y recorre las conversaciones D1–D4→F01/F02/F03 mediante los botones visibles; abre cada conversación de exploración de forma programática, confirma cada jornada y recupera el desenlace desde la ranura. `tests/RunTests.tscn` cubre D0, fallos de guardado y contenido inválido. | PASS local; decisiones educativas aún no emiten eventos canónicos. |
| Privacidad y seguridad del cliente | `scripts/release.py check --channel preview` rechaza claves `sb_secret_`, asignaciones de claves `service_role`/HMAC y JWT con rol `service_role` en fuentes Web, Godot, dashboard o narrativa. `tests/test_release.py` usa credenciales sintéticas para comprobarlo. El juego no tiene chat libre con personas reales. | PASS local; revisión del guion definitivo y del despliegue pendiente. |
| Usabilidad y accesibilidad previstas | Los controles admiten teclado y ratón; la pausa conserva el estado, el texto se ajusta en tres tamaños y la ventana menor de 768×448 detiene el avance. Las opciones de novela visual se desplazan en un panel. | PASS en pruebas locales de los casos cubiertos; verificar en los equipos y resoluciones del laboratorio. |
| Compatibilidad Web | La exportación Godot 4.7.2 pasó `npm run test:browser` en Chrome y Edge a 1152×672, sin errores de consola; el paquete `0.32.1-preview` contiene `index.pck` de 69 021 308 bytes y `index.wasm` de 37 902 138 bytes. | PASS local en ambos navegadores; red y equipo del laboratorio deben comprobarse en la matriz final. El GDD no fija presupuesto de descarga o tiempo de arranque. |
| Mantenibilidad y repetibilidad | CI ejecuta validación narrativa, suites Godot (incluida la ruta completa), pruebas de almacenamiento/backend, navegador y empaquetado; manifiesto SHA-256 comprueba el paquete. | PASS local; GitHub Actions sigue sin ejecución porque el repositorio no tiene remoto. |
| Observabilidad y recuperación | La cola conserva eventos y rechazos seudónimos; las pruebas locales cubren reintentos, acuses parciales, bloqueo entre pestañas, copia de guardado y rollback compatible. | PASS sintético/local; falta E2E en Supabase y verificar una restauración real según el plan contratado. |
| Consistencia de versiones | El manifiesto identifica juego, guardado, narrativa y rúbrica; la guardia bloquea staging mientras haya datos provisionales. | Bloqueado para staging: `PLAYABLE_DRAFT_v0.1` y `TEST_ONLY_P4_v1` no son contenido aprobado. |

## Orden de cierre

1. Sustituir el guion provisional por escenas canónicas completas, destinos y condiciones F01/F02/F03 verificadas; ejecutar la prueba de rutas sobre esos datos. La [auditoría del ZIP](../historia/P5_ZIP_AUDIT_2026-10-28.md) explica qué piezas originales siguen sin confirmarse.
2. Incorporar IDs canónicos y rúbrica aprobada; emitir cada decisión con guardado y evento atómicos y comprobar que solo el backend calcula puntajes.
3. Desplegar P4/P6 en desarrollo, activar Auth anónima, provisionar una cuenta administrativa y completar `npm run test:backend-e2e` con datos sintéticos. Los accesos administrativos y secretos se mantienen fuera del cliente.
4. Repetir QA-01–15 en los navegadores y equipos del laboratorio; medir descarga y arranque reales para fijar un presupuesto de rendimiento, revisar contenido y preparar staging separado con prueba de restauración y rollback.

No se debe retirar la guardia de staging para simular el cierre de estos puntos.
