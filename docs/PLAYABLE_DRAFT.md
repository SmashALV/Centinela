# Historia jugable candidata D1–D4 v0.2

Tras el MOBA, la respuesta de Camila en el chat lleva a un interludio del Narrador sobre Sofi y el día siguiente. Después comienza la exploración del Día 1. El recorrido enlaza seis fragmentos recuperados, una escena nueva D2-04 y los tres desenlaces. El texto literal sigue en `data/narrative/*_RECOVERED_PREVIEW.json` y no se ha editado. El texto nuevo y las condiciones de ruta están en `data/narrative/playable_draft_v0_2.json`, marcado `provisional: true` y `ready_for_publication: false`. La versión v0.1 se conserva para trazabilidad y migración de guardados. La interfaz del jugador no muestra etiquetas de producción.

El archivo v0.2 contiene nueve reacciones de Camila (resultado del MOBA × clase), conectores, reacciones A/B/C, una escena D2-04 redactada, las variantes recuperadas de D3 ubicadas según la elección D2-04, las dos líneas de despedida recuperadas de D1 y cierres nuevos para F01/F02/F03. El jugador puede guardar y reanudar cada línea y opción. El [guion integral para revisión](GUION_EDITORIAL_CANDIDATO_v1.md) distingue cada línea recuperada de cada línea nueva.

Antes de las escenas principales de D1, D2, D3 y D4, Sofi explora un mapa provisional con WASD y abre la conversación al acercarse a Mateo y pulsar F. Cada mapa usa un [fondo generado propio](WORLD_ASSET_PROMPTS.md); D2 sitúa a Mateo junto a un árbol. Las figuras y marcas de interacción siguen dibujadas por código. D4-01, D4-02 y D4-03 continúan sin interrumpirse con otro mapa. La posición y el estado de exploración se guardan en la ranura. Durante la exploración funcionan el celular (E), el objetivo y las pistas de navegación (Tab), además de la pausa. El celular de Sofi conserva el chat grupal; la captura privada de D2 se muestra en la escena desde el teléfono de Mateo y no se copia al de Sofi.

## Regla temporal de desenlace

La tabla reconstruida activa `CONFIANZA_MATEO_SOFI` con D2-04 A/C, D3-01 C, D4-01 A o D4-02 A; activa `RECONOCE_MANIPULACION` con D3-01 A, D4-01 A/B o D4-02 B. D4-03 A lleva a F01; B/C llevan también a F01 si ambas banderas estaban activas, y si no, B lleva a F02 y C a F03. F01 recorre tutor y madre. El guion muestra a Mateo tomando la iniciativa en las rutas B/C protectoras. Las cinco trayectorias se prueban de extremo a extremo desde el resultado del MOBA en `StoryRoutesTests.tscn`.

Esta regla reproduce la recuperación secundaria del ZIP y sigue pendiente de cotejo con la fuente maestra. El final narrativo no aporta puntos. Los `decision_id`/`choice_id` candidatos están en el archivo v0.2 sin puntajes; la [rúbrica candidata](rubric_candidate_v1.json) con dimensión, 0/1/2 y justificación por opción permanece fuera de la exportación del juego. La versión jugable aún no genera eventos educativos, no asigna `story_completed` ni `ending_assigned` y no se envía a Supabase.

## Para reemplazarlo

El equipo narrativo y académico debe revisar el [guion integral](GUION_EDITORIAL_CANDIDATO_v1.md), las condiciones reconstruidas, los seis IDs de decisión y la [rúbrica candidata](rubric_candidate_v1.json). Los puntos son una propuesta razonada, no una validación psicométrica. Tras aprobarlos, se deben congelar versión y textos, crear los archivos canónicos y la rúbrica del servidor, activar eventos educativos con guardado atómico y repetir QA-01/02/11 en desarrollo y staging. Si se cambian IDs o rutas, definir una migración explícita; no reinterpretar los JSON literales recuperados.

Los sprites y fondos de novela visual están en `assets/vn/`. El reemplazo de retratos, escenarios y sonido está descrito en `docs/ASSETS.md`.
