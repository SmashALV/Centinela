# Recursos visuales provisionales y reemplazo

El prototipo no depende de imágenes externas. `scripts/World.gd::_draw()` dibuja habitación, patio, computadora, objetos y Sofi; `scripts/moba/MOBAArena.gd::_draw()` dibuja arena, héroes, torres, bases y proyectiles. Estas formas son los recursos provisionales generados en el proyecto. Se reemplazarán por sprites y fondos sin cambiar los IDs de interacción ni las reglas del combate.

| Recurso a entregar | Formato y tamaño sugeridos | Uso y ubicación futura |
|---|---|---|
| Sofi y amistades en exploración | PNG transparente, 4 direcciones, fotogramas de 32×32 px; una hoja por personaje | `assets/characters/`; reemplaza círculos de `World.gd` |
| Habitación, patio y computadora | Tiles PNG de 32×32 px, capas suelo/objetos/colisión; tamaños según escenas 768×448 | `assets/world/`; reemplaza fondos y muebles de `World.gd` |
| Objetos interactivos | PNG transparente de 32×32 o 64×64 px: alarma, mochila, escritorio, foto, puerta, grupo, PC | `assets/objects/`; mantener posiciones e IDs definidos en `World.gd::configure()` |
| Héroes MOBA | PNG transparente con siluetas claramente distintas para Atacante, Defensor y Soporte; 4 direcciones, 32×32 px | `assets/moba/heroes/`; deben distinguir equipos aliado y rival |
| Torres, bases y ruinas | PNG transparente de 64×64 px; estado intacto y destruido por estructura | `assets/moba/structures/`; reemplaza rectángulos en `MOBAArena.gd` |
| Obstáculo de arena | Tiles PNG de 32×32 px para bloque sólido y bordes; la barrera provisional ocupa 2×4 casillas | `assets/moba/terrain/`; debe conservar la misma colisión y los pasos laterales |
| Proyectiles y habilidad Q | PNG transparente de 16×16 o 32×32 px, variantes por equipo/clase | `assets/moba/effects/`; reemplaza círculos de proyectil |
| Retratos de diálogo | PNG transparente de al menos 256×256 px, cinco expresiones coherentes por personaje | `assets/portraits/`; se conectarán al módulo de diálogos cuando llegue el guion literal |
| Iconos de interfaz | PNG transparente de 32×32 px para celular, objetivo, pausa y controles | `assets/ui/` |

Para reemplazar, entregar los archivos con nombres de personaje/objeto y una licencia o autorización de uso. Mantener la escala pixel art sin interpolación y legibilidad en el viewport lógico de 768×448. El arte actual es deliberadamente esquemático: permite probar reglas y recorrido mientras se preparan los sprites definitivos.
