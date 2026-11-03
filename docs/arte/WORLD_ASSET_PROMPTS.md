# Fondos generados para la exploración D1–D4

Los mapas del Día 0 y su mobiliario separado se documentan en [DAY0_MAP_ASSETS_2026-10-28.md](DAY0_MAP_ASSETS_2026-10-28.md).

Generados con la herramienta integrada `image_gen` el 28-10-2026 y guardados en `assets/world/`. Son fondos PNG completos (aprox. 1672×941 px) para el viewport lógico de 768×448. El juego recorta y escala cada imagen dentro del área explorable, sin alterar el archivo fuente. No contienen personajes, texto ni interfaz. Las figuras de Sofi y Mateo se superponen por código.

Los cuatro PNG transparentes en `assets/world/tiles/` son atlas de cuatro variantes de suelo de 32×32 px generados de forma reproducible por `scripts/generate_world_tiles.gd`. `World.gd` coloca 22×10 celdas sobre el fondo en una `TileMapLayer`; la capa `CollisionBodies` contiene obstáculos `StaticBody2D` que cubren muebles, paredes, jardineras y escaleras. El jugador usa `CharacterBody2D`, de modo que los obstáculos se prueban con el motor de física. Los rectángulos aproximan los objetos de los fondos pintados; el arte final debe reemplazarlos por atlas y formas ajustadas a cada objeto. La prueba física verifica una ruta desde el inicio hasta Mateo en las cuatro jornadas.

| Jornada | Archivo | Ubicación de la interacción |
|---|---|---|
| D1, lobby | `day1_lobby_generated.png` | Mateo en (520, 225) |
| D2, exterior del colegio | `day2_school_exterior_generated.png` | Mateo junto al árbol, (520, 225) |
| D3, pasillo | `day3_corridor_generated.png` | Mateo en (520, 225) |
| D4, patio | `day4_courtyard_generated.png` | Mateo en (520, 225) |

## Prompts finales

### D1

> Use case: stylized-concept. Asset type: production background for a 2D top-down narrative game, Day 1 lobby. Create a clean landscape pixel-art environment only: a school gaming/lobby room with three monitor stations along the upper wall, simple tables, muted blue slate floor, subtle warm light, readable large tile shapes. Strict orthographic top-down / high-angle RPG view, single continuous open walkable floor through the center and lower half; no characters, no text, no labels, no UI, no logos, no borders or mockup frame. Cohesive restrained palette navy, desaturated teal, warm cream, in the style of a polished 32-pixel tile RPG map. Place furniture only along upper edge and far left/right edges so the middle and the area around x=520/768,y=225/448 stay empty for player and NPC sprites. Wide 16:9 landscape composition, crisp pixel edges, no anti-aliased painterly texture.

### D2

> Use case: stylized-concept. Asset type: production background for a 2D top-down narrative game, Day 2 outside a school. Create a clean landscape pixel-art RPG environment only: exterior schoolyard with a recognizable leafy tree in the upper-right quadrant near where Mateo will stand, a modest school facade with windows along the upper-left edge, paved walkway and patches of grass, muted slate blue and sage green with warm late-afternoon light. Strict orthographic top-down / high-angle RPG view, single continuous open walkable floor through the center and lower half; no characters, no text, no labels, no UI, no logos, no borders or mockup frame. Cohesive style with a polished 32-pixel tile RPG map, crisp pixel edges, no anti-aliased painterly texture. Keep x=520/768,y=225/448 and the whole central route empty for character sprites; tree canopy can be above that zone. Wide 16:9 landscape composition.

### D3

> Use case: stylized-concept. Asset type: production background for a 2D top-down narrative game, Day 3 school corridor. Create a clean landscape pixel-art RPG environment only: quiet school passage with windows and noticeboard along the upper wall, a wooden bench toward upper middle-left, a few lockers at far side, muted slate blue-gray floor with warm light and a slightly subdued mood. Strict orthographic top-down / high-angle RPG view, single continuous open walkable floor through center and lower half; no characters, no text, no labels, no UI, no logos, no borders or mockup frame. Cohesive restrained navy, desaturated teal and warm cream palette like a polished 32-pixel tile RPG map; crisp pixel edges, no anti-aliased painterly texture. Keep x=520/768,y=225/448 and central path empty for player and NPC sprites. Wide 16:9 landscape composition.

### D4

> Use case: stylized-concept. Asset type: production background for a 2D top-down narrative game, Day 4 school courtyard. Create a clean landscape pixel-art RPG environment only: calm school patio with three leafy trees along upper edge and side, small wooden benches at far left and right, paved open courtyard in the center, restrained sage green, navy slate and warm cream palette with soft daylight; serious but hopeful mood. Strict orthographic top-down / high-angle RPG view, single continuous open walkable floor through center and lower half; no characters, no text, no labels, no UI, no logos, no borders or mockup frame. Cohesive style with polished 32-pixel tile RPG map, crisp pixel edges, no anti-aliased painterly texture. Keep x=520/768,y=225/448 and central route empty for player and NPC sprites. Wide 16:9 landscape composition.

## Sustitución posterior

Los fondos son imágenes completas; los tiles actuales aportan textura de suelo repetible y las colisiones están definidas por rectángulos independientes, no por píxel. Para el arte final modular se necesitan tiles de 32×32 px para cada tipo de suelo y objeto, con formas físicas ajustadas a los muebles, árboles y paredes. Mantener el punto interactivo de Mateo o actualizarlo en `World.gd`. Los fondos y tiles generados no determinan la narrativa ni la puntuación.
