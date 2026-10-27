# CENTINELA 2.0 — Plan de implementación por fases para Codex
## Versión 1.0 · Ingeniería de entrega · GAME-250 opción C

**Entrada canónica:** `GDD_CENTINELA_2_0.md` y, cuando se incorporen, los JSON que transcriben **literalmente** el guion aprobado D0–D4. **No inventar** diálogos, opciones, puntuaciones o condiciones pedagógicas ausentes. **Diseño cerrado en GAME-250:** no volver a plantear decisiones A/B/C.

## 1. Estrategia de ejecución

**Patrón obligatorio por fase:** inspeccionar repositorio → leer GDD y AGENTS → identificar archivos existentes → implementar cambios mínimos y autocontenidos → añadir pruebas → ejecutar Godot/headless y verificaciones propias → comprobar Definition of Done → registrar resultados y checkpoint Git. No comprometer credenciales privadas ni operar directamente contra producción durante desarrollo.

**Principios transversales:** módulos separados, JSON narrativo como contenido versionado, un flujo de decisión guardado de forma atómica, pruebas desde la fase 0, credenciales segregadas, trazabilidad por versiones y ninguna modificación silenciosa del alcance aprobado.

**Orden recomendado:** P0 fundación; P1 vertical slice Día 0; P2 MOBA completo; P3 persistencia y multitab; P4 Edge Functions y telemetría; P5 Días 1–4 y finales; P6 dashboard; P7 pruebas completas y endurecimiento; P8 staging y producción. Las subfases son decisiones **operativas**, no nuevas preguntas de diseño.

## 2. Estructura propuesta de repositorio

```text
centinela-2/
├── AGENTS.md
├── README.md
├── docs/
│   ├── GDD_CENTINELA_2_0.md
│   ├── PLAN_CODEX_CENTINELA_2_0.md
│   ├── DECISION_REGISTER.md
│   └── TEST_MATRIX.md
├── game/
│   ├── project.godot
│   ├── autoload/
│   │   ├── NarrativeManager.gd
│   │   ├── UIManager.gd
│   │   ├── SaveManager.gd
│   │   ├── SyncManager.gd
│   │   ├── TabLockManager.gd
│   │   └── WebBridge.gd
│   ├── scenes/
│   │   ├── world/{SofiBedroom,SchoolCourtyard,SchoolExterior,ComputerScene}.tscn
│   │   ├── moba/MOBAArena.tscn
│   │   ├── ui/{DialogueUI,PhoneUI,PauseMenu,ObjectiveUI,CombatHUD,MainMenu}.tscn
│   │   └── actors/
│   ├── scripts/
│   │   ├── narrative/{NarrativeValidator,NarrativeMigrationManager}.gd
│   │   ├── combat/
│   │   ├── actors/
│   │   └── ui/
│   ├── data/narrative/{day_0,day_1,day_2,day_3,day_4,endings}.json
│   └── tests/{narrative,persistence,moba}/
├── web/
│   ├── web_bridge.js
│   ├── indexeddb_service.js
│   └── entrypoint/
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed/  # SOLO no producción
├── dashboard/
├── ci/
└── scripts/
```

**Nota:** esta estructura es propuesta de organización para la implementación, no evidencia de que las carpetas y scripts ya existan. Mantener scripts pequeños; centralizar límites de dominio sin repartir `JavaScriptBridge` por todos los controladores.

## 3. Fase P0 — Base de ingeniería y motor narrativo mínimo

**Objetivo:** proyecto exportable a Web, estructura modular, una escena de prueba y flujo de validación verificable.

**Entregables:** proyecto Godot 4 con render 2D y viewport adecuado; autoloads iniciales; controlador de ventanas sin superposiciones; `NarrativeManager` capaz de leer JSON y avanzar en secuencias de índices; `NarrativeValidator.gd`; ejecución `--headless` con salida de proceso distinta de cero ante errores críticos; configuración de test `development`; documentación básica del arranque.

**Pruebas obligatorias:** Godot abre sin errores; escenario top-down de prueba; teclado y F; ventana de diálogos modular; parser rechaza índice imposible, variable no reconocida y decisión duplicada; UI no introduce estado educativo.

**Definition of Done:** README reproducible, tests ejecutados con log, errores críticos cero, commit delimitado a P0.

**Prompt Codex P0:**

> Lee `AGENTS.md` y el GDD. Inspecciona el proyecto existente antes de editar. Implementa exclusivamente P0: proyecto Godot 4 web compatible, escena 2D, movimiento básico, UI modular, lector narrativo JSON secuencial y validador ejecutable headless. No inventes contenido narrativo. Crea fixtures sintéticos claramente marcados `TEST_ONLY` para pruebas, jamás eventos de investigación. Ejecuta pruebas; informa archivos, comandos, resultados y pendientes técnicos. No continúes a P1 sin satisfacer DoD.

## 4. Fase P1 — Vertical slice jugable del Día 0

**Objetivo:** recorrer el Día 0 desde habitación → patio → PC → MOBA básico → retorno a narrativa, con guardado local mínimo operativo. Demostrar un recorrido jugable completo, no solo componentes aislados.

**Entregables:** alarma y mochila obligatorias, escritorio/PC/foto opcionales; interacción de patio con grupo; desktop ficticio; selección de clases; MOBA funcional inicial de 5v5 y cronómetro; `DialogueUI` y `PhoneUI` prototipos; IndexedDB con `save_slots` y `save_snapshots`, `WebBridge` mínimo, reabrir guardado Día 0. Guiarse por guion literal existente para textos; si no está disponible, dejar contrato y fixtures visuales rotulados provisionales, no contenidos presentados como definitivos.

**Pruebas:** carga/continuación en navegador real; sin saltar objeto obligatorio; transición PC→MOBA; retorno pospartida; texto pequeño/mediano/grande sin recorte; F y E no colisionan con diálogos; la partida del MOBA reinicia según regla si hubo cierre.

**Definition of Done:** se puede completar Día 0 de inicio a fin; no hay crash; la persistencia local funciona en navegador y los nombres/versiones del código quedan documentados.

**Prompt Codex P1:**

> Construye un vertical slice de Día 0 sobre P0. Implementa escenas y UI reutilizables, interacción obligatoria de habitación, patio, computador, selección de clase y combate MOBA inicial de hasta 180 s. Introduce guardado local con IndexedDB y WebBridge; no implementes el combate fuera de sus parámetros aprobados ni inventes diálogos ausentes. Prueba en exportación web, documenta qué assets son temporales y registra evidencias de DoD.

## 5. Fase P2 — MOBA completo con IA y pruebas de reglas

**Objetivo:** reemplazar el combate inicial por las reglas oficiales del GDD.

**Entregables:** arena 36×20, cámara 24×14, colisiones y bloqueos, 5+5 héroes, 3 clases y Q, IA simétrica, regeneración/retirada, towers/base, proyectiles con obstáculos, derrumbe a ruinas, respawn, invulnerabilidad, victoria inmediata o desempate a 180 s, narración/pantalla de resultados y nueve variantes de reacción Camila enlazadas a los textos canónicos.

**Pruebas:** daño básico 12; rango 6, CD 1; Q archer 24 vs héroes/12 vs estructuras y penetración2; escudos 20/10, 4s; aura 25%, 5s; torres 240HP, 12 cada1.5s, rango7; base400HP y regen; tie-break; cámara ante muerte de Sofi; eventos MOBA resultado único. Test determinista de simulación con seeds y registros, sin afectar métricas educativas.

**Definition of Done:** demo MOBA vence/empata/pierde por las reglas; completitud de la ruta Día 0; no altera D1–D4.

**Prompt Codex P2:**

> Implementa el MOBA de Centinela 2.0 estrictamente según la sección 6 del GDD. Añade tests numéricos de ataque, habilidades, IA, respawn, estructuras y time-out. Reutiliza escena/UI/guardado existente. Evita reescribir la arquitectura narrativa. Verifica exportación web y logs de tests; entrega evidencia y diferencias pendientes.

## 6. Fase P3 — Persistencia robusta y bloqueo multitab

**Objetivo:** tres ranuras independientes con seguridad transaccional, snapshots JSON versionados y recuperación exacta.

**Entregables:** stores `save_slots`, `save_snapshots`, `event_outbox`, `sync_status`, `save_credentials`; serialización validada; transacción única `save_decision_atomic`; idempotencia persistente; `TabLockManager` lease+generation, bloqueo y renovación; WebBridge request/response JSON versionados y errores tipados; migraciones documentadas; tests `SaveStateTestRunner.gd` y escenarios manuales de browser.

**Pruebas:** rollback transacción; bloqueo concurrente dos pestañas; pestaña vieja rechazada tras reacquirir; respuesta perdida tras commit no duplica; guardados de tres ranuras sin contaminación; fallo persistente muestra reintento y evita continuar; reiniciar conserva estado y chat; reabrir MOBA reinicia misma clase.

**Definition of Done:** pruebas headless de serialización + pruebas web reales de IndexedDB pasan; ninguna elección se aplica antes del commit local.

**Prompt Codex P3:**

> Completa el almacenamiento modular IndexedDB y WebBridge según GAME-234–243, integrando operaciones atómicas, idempotencia y bloqueo renovable por partida. Crea test suite GDScript con JSON de fixtures y pruebas browser para concurrencia. No expongas credenciales en logs, no modifiques datos de producción. La prueba de cierre inesperado debe demostrar reinicio correcto de MOBA.

## 7. Fase P4 — Backend Supabase y telemetría temprana

**Objetivo:** asegurar canal de métricas oficial antes de terminar los días narrativos.

**Entregables:** migraciones SQL controladas; proyecto development independiente; Supabase Auth anónimo por apertura, posesión de token secreto por guardado; Edge Functions `register_save`, `claim_save`, `ingest_events`, `finalize_sync` (nombres de referencia), RLS, validación de orden narrativo/UUID/secuencia; rúbrica D1–D4 versionada y calculada en servidor; cola de hasta 10 eventos/10s con reintentos y acuses parciales.

**Pruebas:** que una identidad anónima no lea otra partida; que reclamar save revoque antiguo permiso; que event_id duplicado no genere doble puntaje; faltantes en sequence mantienen sync parcial; ruptura de internet no pierde outbox; final Fxx e informe por rubrica; que cliente no contenga service role; pruebas contra **desarrollo/staging únicamente**.

**Definition of Done:** telemetría end-to-end demostrada con participante de prueba; D1–D4 calculadas solo por backend; error handling verificable.

**Prompt Codex P4:**

> Implementa el backend Supabase usando migrations, Auth anónima, Edge Functions y RLS, conforme a GDD secciones 7–11. Nunca expongas secretos service role. Usa rúbrica sintética versionada en desarrollo hasta incorporar la matriz académica auténtica; no la presentes como rúbrica aprobada. Integra `SyncManager` y comprueba eventos idempotentes, secuencias faltantes, acuses parciales y aislamiento entre partidas.

## 8. Fase P5 — Historia Días 1–4, celulares y finales

**Objetivo:** juego narrativo completo de cinco días sobre arquitectura validada.

**Entregables:** transcripción literal del guion fuente a `day_1.json...day_4.json` y `endings.json`; capturas de chat ficticias, chat privado y smartphone contextual; Kairo como invitado temporal; escenas escolares y exteriores reutilizadas; variables narrativas, rutinas y finales F01/F02/F03; confirmación neutral de decisiones, historial y pistas; migraciones y tests JSON por cada jornada.

**Pruebas:** 100% de alternativas de las decisiones evaluables; rutas críticas; no omisión de conversaciones; no hay encuentro real; resultado MOBA no condiciona grooming; sin respuestas inventadas ni personajes renombrados; narrativa mantiene versiones.

**Definition of Done:** se juegan D0–D4 y los tres finales, con eventos educativos consistentes y sincronización; el guion íntegro está versionado y validado.

**Prompt Codex P5:**

> Con las fuentes textuales del guion canónico, construye las jornadas 1–4 y finales usando JSON secuencial y el motor existente. No reescribas un diálogo aprobado ni rellenes opciones desconocidas. Si falta un tramo literal, crea un reporte de bloqueo documental con archivo/posición, y continúa implementando los demás tramos verificables. Simula rutas y comprueba los tres finales, sus flags y eventos educativos.

## 9. Fase P6 — Dashboard del investigador

**Objetivo:** panel separado para clasificación de cohortes, validación manual y reportes.

**Entregables:** acceso administrativo compartido aprobado; sesiones SES y estados, asociación manual CTN validado/prueba/no validado, motivos y auditoría; dimensión D1–D4, score global y cobertura; listado de eventos/decisiones; anomalías de sincronización; exportación CSV/XLSX de los 3 datasets; cierre/reapertura, eventos tardíos y versiones inmutables `SES-001 v1/v2`.

**Pruebas:** sin cuenta estudiante; reportes excluyen pruebas/no validados; un evento tardío no altera reporte publicado sin nueva versión; exportaciones sin secretos; data lineage rubric/save; contexto de fecha Lima.

**Definition of Done:** dashboard conectado en development, validación manual funcional, análisis exportable reproducible.

**Prompt Codex P6:**

> Implementa un dashboard web independiente con administración de sesiones, validación manual CTN, D1–D4, cobertura y exportaciones. Implementa snapshots inmutables de informes y auditoría de cambios. Nunca vincules nominalmente un alumno al juego ni expongas token secreto. Verifica tests de filtrado y permisos; no usar datasets reales para desarrollo.

## 10. Fase P7 — QA integral, accesibilidad y controles de seguridad

**Objetivo:** cumplir la matriz QA-01 a QA-15 y la opción GAME-249 A, pruebas técnicas internas.

**Entregables:** suites headless, navegación real del navegador, casos de interrupción/recuperación, revisión mínima de contenido adecuado para menores, revisión de seguridad de Edge Functions, matrices por navegador y resoluciones del laboratorio, evidencia versionada de cada caso QA.

**Pruebas críticas:** texto grande sin recortes, sin doble interfaz principal, pausa por pérdida foco/tamaño insuficiente, revertir sin duplicación, navegación 1/2/3 y ratón, MOBA equilibrio determinista, restauración por slots, telemetry ausencia de PII, no notas visibles en cliente.

**Definition of Done:** sin fallos críticos abiertos; evidencias de pruebas técnicas internas; expediente de aprobación para staging. No declarar demostrada eficacia pedagógica por el mero pase de tests.

**Prompt Codex P7:**

> Ejecuta la matriz de aceptación íntegra. Para cada fallo crea reproducciones mínimas y pruebas de regresión; prioriza integridad de datos, rutas educativas y privacidad. Genera reporte de pruebas con PASS/FAIL, evidencia y versión del juego. Mantén el alcance GAME-249 A (pruebas técnicas internas; revisión ética institucional es independiente).

## 11. Fase P8 — Entrega reproducible, staging y producción

**Objetivo:** empaquetado estable y despliegue trazable.

**Entregables:** CI que ejecuta validador, tests de rutas y guardado, exportación web, checklist de secrets, despliegue staging; aprobación manual para production; versionado congelado en sesiones; rollback compatible; revisión de capacidades reales de backups del plan Supabase antes de operar con menores; manuales breves estudiante/investigador y README de recuperación.

**Pruebas:** instalación desde cero en staging, e2e de una partida de prueba, decisión→IndexedDB→Supabase→dashboard→reporte; ensayo de rollback sin cambiar records; listas de cambios; versión narrativa y rúbrica capturada.

**Definition of Done:** compilación web aprobada en staging, autorización de promoción, evidencia de restauración/reversión y conformidad con requisitos institucionales/éticos aplicables.

**Prompt Codex P8:**

> Prepara release reproducible mediante CI/CD. Publica automáticamente solo en staging; promoción manual a producción y congelación durante sesiones. Añade rollback con chequeo de compatibilidad, sin suponer capacidades de backup no contratadas. Genera manifiesto de build y manual operativo. No publiques producción sin aprobación humana explícita.

## 12. Orden transversal de validaciones

| Hito | Puerta de calidad |
|---|---|
| Cambio JSON | Validador GDScript de estructura y migración |
| Cambios de decisiones | Casos JSON independientes, 100% alternativas evaluables |
| Cambio de persistencia | Tests save/load, atomicidad, multi-tab e idempotencia |
| Cambio MOBA | Tests mecánicos numéricos y simulación determinista |
| Cambio backend | Tests de autorización, secuencia, rúbrica y sincronización |
| Antes de release | Suite completa, exportación Web, pruebas reales navegador |
| Antes de producción | Staging aceptado, autorización manual y revisión metodológica/ética separada |

## 13. Plantillas del contrato narrativo

Un ejemplo de formato se incluye como `examples/narrative_TEST_ONLY.json`. Contiene **datos ficticios de estructura** y NO sustituye el guion aprobado. El esquema de conversación utilizará arrays de índices; migraciones explícitas deberán mapear índices. El sistema puede incorporar IDs internos estables para entidades de test y de decisión sin convertir el diálogo a un grafo por identificadores, pues GAME-225 A aprobó índices numéricos.

## 14. Gestión de riesgos y criterios de no regresión

| Riesgo | Control acordado |
|---|---|
| Diálogo ausente o recreado | No inventar; incorporar guion literal y validar antes de release. |
| Pérdida de evento educativo | Commit atómico, outbox y backend idempotente. |
| Dos pestañas reescribiendo | Lease renovable + generación comprobada dentro de transacción. |
| Nueva versión invalida partida | Migración versionada, fallback sin destruir original. |
| Supabase rechaza lote parcial | Reconocer eventos individualmente y retener faltantes. |
| Cambios durante sesión | Freeze + aprobación para corrección urgente. |
| Rúbrica alterada retroactivamente | Versiones congeladas y auditoría de recalificación. |
| Uso de datos ficticios en producción | Entornos separados y filtros oficiales de elegibilidad. |
| Desalineación con ficha académica | Actualización documental del diseño y método sin alterar GAME-001–250. |

## 15. Entrega final por fase

Todo reporte de Codex debe contener: **(i)** archivos creados/modificados; **(ii)** reglas GAME implementadas; **(iii)** tests ejecutados y resultados; **(iv)** capturas/logs esenciales; **(v)** restricciones pendientes **sin pedir nuevas decisiones de diseño**; **(vi)** comandos reproducibles; **(vii)** confirmación de checkpoint Git. Ninguna fase debe comenzar asumiendo que existe código que todavía no se ha inspeccionado.
