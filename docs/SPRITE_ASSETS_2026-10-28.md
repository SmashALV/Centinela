# Sprites provisionales generados el 28-10-2026

Se usó la herramienta integrada `image_gen` para generar PNG con transparencia real. Los sprites son propuestas visuales reemplazables; los retratos existentes sirvieron como referencia de Sofi, Mateo, Bruno, Camila y Sebas. No representan diseños aprobados.

| Grupo | Archivos en el proyecto | Uso actual |
|---|---|---|
| Personajes | `assets/characters/{sofi,mateo,bruno,camila,sebas}_directions.png` | Exploración D0–D4, cuatro vistas estáticas |
| Objetos | `assets/objects/{alarm,backpack,desk,photo,door,pc}.png` | Habitación, salida y computadora; `door.png` se comparte con la salida |
| Héroes | `assets/moba/heroes/{attacker,defender,support}_directions.png` | Tres clases del MOBA, cuatro vistas estáticas |
| Estructuras y terreno | `assets/moba/structures/{tower,base,ruin}.png`, `assets/moba/terrain/barrier_2x4.png` | Torres, bases, ruinas y barrera central |
| Efectos | `assets/moba/effects/{projectile,attack_q,shield_q,support_q}.png` | Disparos, proyectil perforante, escudo y apoyo |
| Interfaz | `assets/ui/{phone,objective,pause,controls}.png` | Encabezados de celular, objetivo, pausa y menú |

Las hojas de personajes y héroes usan la misma cuadrícula 2×2: **arriba izquierda = abajo/frente; arriba derecha = arriba/espalda; abajo izquierda = izquierda; abajo derecha = derecha**. Las dimensiones de los PNG fuente varían; `World.gd` y `MOBAArena.gd` calculan los cuadrantes a partir del tamaño de cada imagen. Se muestran a 46×46 y 54×54 px respectivamente. Son vistas de reposo: aún faltan fotogramas de caminar, animaciones de ataque y una limpieza pixel a pixel a resolución final.

## Prompts de generación

Cada archivo tuvo una llamada independiente a `image_gen`, con `transparent_background=true`.

- **Personajes:** «Transformar el retrato del personaje en una hoja transparente de pixel art de cuerpo entero, cuatro vistas en cuadrícula 2×2, misma ropa, proporciones y escala, perspectiva ortográfica RPG, silueta legible, sin texto, fondo ni otros personajes». Se conservaron pelo y ropa de cada retrato: Sofi teal y cabello largo; Mateo azul y rizado; Bruno borgoña y gafas; Camila coral y coleta; Sebas amarillo y cabello puntiagudo.
- **Héroes:** «Una hoja transparente de cuatro vistas para una clase de MOBA top down, pixel art legible a tamaño de tile; Atacante ágil con energía ámbar, Defensor robusto con escudo teal, Soporte con báculo verde; sin fondo ni texto». El Defensor requirió una segunda llamada de extracción de fondo para obtener alfa transparente.
- **Objetos:** «Un objeto aislado en pixel art ortográfico, centrado sobre alfa transparente, paleta azul marino, teal, crema y madera, legible a 32–64 px; sin texto ni extras». Se especificó por separado alarma digital, mochila, escritorio, foto familiar no identificable, puerta y estación de PC.
- **Estructuras y terreno:** «Una estructura aislada de MOBA top down en piedra, latón y cristal teal, alfa transparente, silueta clara». Se especificó por separado torre, base, ruina y barrera vertical de 2×4 casillas.
- **Efectos:** «Un efecto aislado de pixel art con transparencia, legible a 16–32 px». Se especificó por separado proyectil azul, tajo ámbar, aro de escudo cian y aro de apoyo verde.
- **Interfaz:** «Un icono cuadrado aislado de pixel art, paleta marino/teal/crema, alfa transparente y lectura a 32 px». Se especificó por separado celular, objetivo, pausa y cruceta.

## Sustitución por arte final

Conserva las rutas y nombres de archivo o actualiza los mapas `CHARACTER_SHEETS`, `OBJECT_SPRITES`, `HERO_SHEETS` y `UI_ICONS`. Si reemplazas una hoja de direcciones, conserva los cuatro cuadrantes indicados. Para animación, introduce fotogramas por dirección y modifica el selector de región; las hojas actuales no tienen caminar. Ajusta `OBJECT_SIZES` y las posiciones de etiquetas si cambian las siluetas. La barrera mantiene su colisión de 2×4 casillas aunque cambie el dibujo; actualiza el recorte de `BARRIER_SPRITE` si cambia el lienzo. Ningún sprite determina eventos educativos ni resultados narrativos.

El paquete no incluye expresiones nuevas para retratos de diálogo porque la fuente recuperada no define qué expresión corresponde a cada línea. Los cinco retratos neutros existentes siguen activos.
