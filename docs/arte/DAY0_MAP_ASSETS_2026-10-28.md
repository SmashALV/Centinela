# Mapas del Día 0: inventario y comprobación visual

El 28-10-2026 se usó la herramienta integrada `image_gen` para crear tres fondos y seis sprites de mobiliario. Cada imagen tuvo una llamada independiente; los fondos se generaron sin transparencia usando un mapa D1 o D4 como referencia visual, y los muebles sobre alfa transparente. Los archivos seleccionados se copiaron al proyecto. Los tres atlas de suelo de 128×32 px se generaron mediante `scripts/generate_world_tiles.gd`: cuatro celdas de 32×32 px por mapa.

| Escena | Fondo | Atlas de suelo | Props separados | Colisión |
|---|---|---|---|---|
| Habitación de Sofi | `assets/world/day0_bedroom.png` | `assets/world/tiles/day0_bedroom_floor.png` | Cama, armario, librero y planta; alarma, escritorio, foto, mochila y puerta existentes | Pared superior y huellas de cama, escritorio, armario, librero y planta |
| Patio D0 | `assets/world/day0_courtyard.png` | `assets/world/tiles/day0_courtyard_paving.png` | Tres árboles, dos bancas, dos plantas y puerta de salida; personajes existentes | Fachada superior, troncos/jardineras, bancas y macetas |
| Sala de computadora | `assets/world/day0_computer_room.png` | `assets/world/tiles/day0_computer_floor.png` | Librero y planta; estación de PC existente | Pared superior y huellas de librero, PC y planta |

Los seis props nuevos están en `assets/world/props/{bed,wardrobe,bookshelf,tree,bench,plant}.png`. `World.gd` mantiene el fondo en `PaintedBackground`, el suelo en `GroundTiles`, los rectángulos físicos en `CollisionBodies` y los props como sprites dibujados encima. Los IDs de interacción y los guardados no dependen del arte. Las colisiones bloquean la base de los árboles y muebles, no toda la copa transparente. La cama, banca y PC fueron comprobadas con `CharacterBody2D.test_move`; también se comprobaron rutas libres a los objetivos de las tres escenas.

## Prompts de generación

- **Habitación:** «Cascarón arquitectónico de la habitación adolescente de Sofi al amanecer, pixel art RPG ortográfico, pared violeta azul con ventana cálida, suelo de baldosas marino y malva, gran área central vacía. Sin cama, muebles, objetos, personajes, texto ni interfaz». Referencia de estilo: `day1_lobby_generated.png`.
- **Patio:** «Patio escolar pavimentado, fachada en borde superior, luz cálida, área central vacía para cuatro amistades; sin árboles, bancas, jardineras, personajes, texto ni interfaz». Referencia: `day4_courtyard_generated.png`.
- **Sala de computadora:** «Habitación de estudio al atardecer, pared azul oscura y ventana alta lateral, suelo azul, centro libre para estación de PC separada; sin muebles, PC, personas, texto ni interfaz». Referencia: `day1_lobby_generated.png`.
- **Props:** «Sprite aislado de pixel art RPG visto desde arriba o ángulo alto, centrado, fondo transparente, sin suelo, pared, texto ni personajes». Variantes específicas: cama individual con edredón malva; armario azul de dos puertas; librero con libros de colegio; árbol verde con jardinera circular; banca de madera y metal; planta de maceta azul.

## Verificación de los demás mapas

| Mapa | Recurso ya disponible | Estado físico |
|---|---|---|
| D1 lobby | `day1_lobby_generated.png` y `tiles/day1_lobby_floor.png` | Mobiliario y paredes bloquean; ruta a Mateo libre |
| D2 exterior | `day2_school_exterior_generated.png` y `tiles/day2_exterior_paving.png` | Banca, fachada y jardineras bloquean; ruta a Mateo libre |
| D3 pasillo | `day3_corridor_generated.png` y `tiles/day3_corridor_floor.png` | Pared y extremos de escalera bloquean; ruta a Mateo libre |
| D4 patio | `day4_courtyard_generated.png` y `tiles/day4_courtyard_paving.png` | Jardineras y fachada bloquean; ruta a Mateo libre |

Los fondos D1–D4 ya muestran su mobiliario pintado dentro de la imagen; sus colisiones están en `DRAFT_BLOCKS` y son rectángulos aproximados. Para un atlas modular definitivo de esos cuatro mapas aún se necesitan sprites de cada mueble y formas de colisión ajustadas al arte final. Las pruebas actuales verifican barreras representativas y una ruta libre, no correspondencia exacta píxel por píxel.

Para sustituir los recursos provisionales, conserva nombres y rutas o actualiza `DAY0_BACKGROUNDS`, `GROUND_TILES`, `PROP_SPRITES`, `SCENE_PROPS` y `DAY0_BLOCKS` en `World.gd`. Si cambias dimensiones o posiciones de muebles, ajusta sus rectángulos físicos y vuelve a probar que los objetos interactivos quedan a menos de 49 px de una posición alcanzable. Entrega la licencia o autorización de uso del arte final.
