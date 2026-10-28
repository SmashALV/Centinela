# Recursos visuales provisionales y reemplazo

`scripts/World.gd::_draw()` dibuja habitación, patio inicial, computadora, iconos de objetos y personajes con colores, peinados y nombres provisionales distintos. Los [cuatro fondos D1–D4 generados](WORLD_ASSET_PROMPTS.md) ya se usan en la exploración. `scripts/moba/MOBAArena.gd::_draw()` dibuja arena, héroes con marcas propias para los cinco aliados y una X para rivales, torres y bases rotuladas, y proyectiles. Estas formas son provisionales. Los cinco retratos neutros de diálogo fueron generados con imagegen y están incluidos en el proyecto. Se reemplazarán por arte definitivo sin cambiar los IDs de interacción, la marca del siguiente objetivo ni las reglas del combate.

| Recurso a entregar | Formato y tamaño sugeridos | Uso y ubicación futura |
|---|---|---|
| Sofi y amistades en exploración | PNG transparente, 4 direcciones, fotogramas de 32×32 px; una hoja por personaje | `assets/characters/`; reemplaza círculos de `World.gd` |
| Habitación, patio y computadora | Tiles PNG de 32×32 px, capas suelo/objetos/colisión; tamaños según escenas 768×448 | `assets/world/`; reemplaza fondos y muebles de `World.gd` |
| Escenarios D1–D4 | Actualmente fondos PNG completos generados; para arte final, tiles de 32×32 px y capas de suelo, mobiliario y colisión | `assets/world/`; reemplaza `World.gd::DRAFT_BACKGROUNDS` y conserva la posición e interacción de Mateo |
| Objetos interactivos | PNG transparente de 32×32 o 64×64 px: alarma, mochila, escritorio, foto, puerta, grupo, PC | `assets/objects/`; mantener posiciones e IDs definidos en `World.gd::configure()` |
| Héroes MOBA | PNG transparente con siluetas claramente distintas para Atacante, Defensor y Soporte; 4 direcciones, 32×32 px | `assets/moba/heroes/`; deben distinguir equipos aliado y rival |
| Torres, bases y ruinas | PNG transparente de 64×64 px; estado intacto y destruido por estructura | `assets/moba/structures/`; reemplaza rectángulos en `MOBAArena.gd` |
| Obstáculo de arena | Tiles PNG de 32×32 px para bloque sólido y bordes; la barrera provisional ocupa 2×4 casillas | `assets/moba/terrain/`; debe conservar la misma colisión y los pasos laterales |
| Proyectiles y habilidad Q | PNG transparente de 16×16 o 32×32 px, variantes por equipo/clase | `assets/moba/effects/`; reemplaza círculos de proyectil |
| Retratos de diálogo | PNG transparente de al menos 256×256 px, cinco expresiones coherentes por personaje | `assets/portraits/`; el Día 0 usa un retrato neutro por Sofi, Mateo, Bruno, Camila y Sebas |
| Iconos de interfaz | PNG transparente de 32×32 px para celular, objetivo, pausa y controles | `assets/ui/` |
| Música de exploración y MOBA | Bucle WAV u OGG de 6–12 s, sin voces, sin silencios bruscos al repetir; nivel moderado | Sustituir `assets/audio/explore_loop.wav` y `arena_loop.wav`; `AudioManager.gd` selecciona el contexto |
| Efectos de interfaz y combate | WAV u OGG mono, 0,1–0,5 s, sin voces; cuatro archivos para confirmación, interacción, habilidad y resultado | Sustituir `assets/audio/confirm.wav`, `interact.wav`, `ability.wav` y `result.wav` |

Para reemplazar, entregar los archivos con nombres de personaje/objeto y una licencia o autorización de uso. Mantener los sprites del mundo y MOBA en escala pixel art sin interpolación y legibles en el viewport lógico de 768×448. Los retratos ilustrados se escalan con filtro lineal. El arte de mundo y combate actual es deliberadamente esquemático: permite probar reglas y recorrido mientras se preparan los sprites definitivos.

Los retratos actuales son PNG transparentes de 1254×1254 px y aparecen a 110×110 px junto al texto del Día 0. Sustituye `sofi_neutral.png`, `mateo_neutral.png`, `bruno_neutral.png`, `camila_neutral.png` y `sebas_neutral.png` en `assets/portraits/` conservando nombres y transparencia; o actualiza el mapa `PORTRAITS` en `scripts/Main.gd`. Se requieren cinco expresiones coherentes por personaje y un mapeo aprobado de expresión por línea para la versión definitiva. El guion recuperado no especifica ese mapeo, por lo que el prototipo muestra solo expresión neutra. Apariencia, peinado, accesorios y ropa de estas imágenes son propuestas provisionales, no diseños aprobados. Los [prompts usados y revisados](PORTRAIT_PROMPTS.md) documentan cómo se generaron.

Los seis WAV actuales fueron generados por `scripts/generate_audio.py` como sonidos provisionales propios. Para reemplazarlos, conserva los nombres y rutas o actualiza el mapa de `scripts/AudioManager.gd`; usa música libre de voces y con licencia verificable. Si cambias los bucles, comprueba que empalmen sin chasquidos y que los efectos sigan siendo opcionales. Los controles de Pausa permiten poner música o efectos en 0 %, así que ninguna señal educativa depende exclusivamente del sonido.
