# Matriz de aceptación — Centinela 2.0

Todos los casos deben registrarse con versión, resultado PASS/FAIL, evidencia y responsable. Las descripciones completas están en la sección 15 del GDD.

La ejecución técnica del 27 de octubre de 2026, con estados y límites por caso, está en [`P7_QA_2026-10-27.md`](P7_QA_2026-10-27.md).

| ID | Categoría | Criterio | Fase inicial |
|---|---|---|---|
| QA-01 | Narrativa | D0–D4 y finales F01/F02/F03 coherentes | P5 |
| QA-02 | Narrativa educativa | Todas las alternativas evaluables cubiertas | P5 |
| QA-03 | JSON | Validador impide errores críticos y migraciones inválidas | P0/P5 |
| QA-04 | MOBA | Estadísticas, estructuras, habilidades, victoria y empate | P2 |
| QA-05 | UX | Pausa y controles, responsive, foco y tamaños de fuente | P1/P7 |
| QA-06 | Persistencia | Guardado exacto y reanudación MOBA especial | P3 |
| QA-07 | Atomicidad | Error DB impide avance y registros parciales | P3 |
| QA-08 | Concurrencia | Multitab/fencing y bloqueo seguro | P3 |
| QA-09 | Idempotencia | Duplicados de operación no duplican eventos | P3/P4 |
| QA-10 | Sincronización | Offline, acuse parcial, huecos seq | P4 |
| QA-11 | Puntuación | D1–D4 servidor, sin efecto de MOBA/tiempo | P4 |
| QA-12 | Reportes | Eventos tardíos y reportes inmutables | P6 |
| QA-13 | Privacidad | CSV/XLSX sin secretos ni PII | P6 |
| QA-14 | Operación | Staging + freeze + rollback compatible | P8 |
| QA-15 | Seguridad infantil | Sin chat real ni contenido explícito | P7 |
