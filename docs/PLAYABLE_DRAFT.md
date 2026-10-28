# Borrador jugable D1–D4 v0.1

Tras el MOBA, **Continuar borrador jugable** permite recorrer los seis fragmentos recuperados de D1–D4 y llegar a un desenlace. El texto literal sigue en `data/narrative/*_RECOVERED_PREVIEW.json` y no se ha editado para construir este flujo. Todo texto nuevo está en `data/narrative/playable_draft_v0_1.json`, marcado `provisional: true` y `ready_for_publication: false`; la interfaz lo presenta como **BORRADOR**.

El archivo nuevo contiene nueve reacciones de Camila (resultado del MOBA × clase), un conector para cada una de las seis escenas y los cuatro extractos de final, y 18 reacciones breves (A/B/C en cada escena). El jugador puede guardar y reanudar cada línea y opción. Las líneas recuperadas cuya posición no consta permanecen accesibles por separado.

## Regla temporal de desenlace

La última opción de `D4_03_A` determina el extracto siguiente: A → `F01_A` → `F01_B` → resumen F01; B → F02; C → F03. Las decisiones anteriores se conservan y aparecen en el resumen, pero no alteran esa ruta. Esta regla solo permite probar un recorrido completo. No representa la fórmula oficial de finales ni una puntuación educativa. El borrador no genera eventos de decisión, no asigna `story_completed` ni `ending_assigned` y no se envía a Supabase.

## Para reemplazarlo

Se requiere el guion canónico aprobado con cada conector, las nueve variantes de Camila, las reacciones y destinos de las 18 opciones, el orden de las líneas recuperadas sin posición, la intercalación del chat de F03 y las condiciones oficiales para F01/F02/F03. También hacen falta los IDs definitivos y la rúbrica educativa validada si se desea registrar decisiones. Crear archivos canónicos nuevos y una migración de guardados para cualquier cambio de IDs o rutas; no reinterpretar en sitio los JSON recuperados.

No se añadieron imágenes ni audio nuevos en esta fase. El reemplazo de retratos, escenarios y sonido está descrito en `docs/ASSETS.md`.
