# Borrador jugable D1–D4 v0.1

Tras el MOBA, la respuesta de Camila en el chat y un único **Continuar** llevan a la exploración del Día 1. El recorrido enlaza los seis fragmentos recuperados de D1–D4 y llega a un desenlace. El texto literal sigue en `data/narrative/*_RECOVERED_PREVIEW.json` y no se ha editado para construir este flujo. Todo texto nuevo está en `data/narrative/playable_draft_v0_1.json`, marcado `provisional: true` y `ready_for_publication: false`; esas marcas de producción no aparecen en la interfaz del jugador.

El archivo nuevo contiene nueve reacciones de Camila (resultado del MOBA × clase), un conector para cada una de las seis escenas y los cuatro extractos de final, y 18 reacciones breves (A/B/C en cada escena). El jugador puede guardar y reanudar cada línea y opción. Las líneas recuperadas cuya posición no consta permanecen accesibles por separado.

Antes de las escenas principales de D1, D2, D3 y D4, Sofi explora un mapa provisional con WASD y abre la conversación al acercarse a Mateo y pulsar F. Cada mapa usa un [fondo generado propio](WORLD_ASSET_PROMPTS.md); D2 sitúa a Mateo junto a un árbol. Las figuras y marcas de interacción siguen dibujadas por código. D4-01, D4-02 y D4-03 continúan sin interrumpirse con otro mapa. La posición y el estado de exploración se guardan en la ranura. Durante la exploración funcionan el celular (E), el objetivo y las pistas de navegación (Tab), además de la pausa. El celular de Sofi conserva el chat grupal; la captura privada de D2 se muestra en la escena desde el teléfono de Mateo y no se copia al de Sofi.

## Regla temporal de desenlace

La última opción de `D4_03_A` determina el extracto siguiente: A → `F01_A` → `F01_B` → resumen F01; B → F02; C → F03. Las decisiones anteriores se conservan y aparecen en el resumen, pero no alteran esa ruta. Esta regla solo permite probar un recorrido completo. No representa la fórmula oficial de finales ni una puntuación educativa. El borrador no genera eventos de decisión, no asigna `story_completed` ni `ending_assigned` y no se envía a Supabase.

## Para reemplazarlo

Se requiere el guion canónico aprobado con cada conector, las nueve variantes de Camila, las reacciones y destinos de las 18 opciones, el orden de las líneas recuperadas sin posición, la intercalación del chat de F03 y las condiciones oficiales para F01/F02/F03. También hacen falta los IDs definitivos y la rúbrica educativa validada si se desea registrar decisiones. Crear archivos canónicos nuevos y una migración de guardados para cualquier cambio de IDs o rutas; no reinterpretar en sitio los JSON recuperados.

Los sprites y fondos de novela visual están en `assets/vn/`. El reemplazo de retratos, escenarios y sonido está descrito en `docs/ASSETS.md`.
