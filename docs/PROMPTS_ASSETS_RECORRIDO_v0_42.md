# Prompts de los assets que faltan en el recorrido · v0.42

Inventario de lo que el recorrido diario (casa → calle → colegio → tutoría → clase → despedida → regreso → cena → cuarto) todavía muestra con arte reutilizado, dibujado por código o sin ilustración, más los sprites pendientes. Cada asset tiene su archivo de destino, tamaño, dónde se ve y su prompt.

Los prompts siguen el formato de `docs/ROUTINE_ASSET_PROMPTS_2026-10-29.json`: en inglés, una imagen por llamada, con referencias **solo de estilo o identidad**. Los fondos van sin transparencia; los sprites y personajes, con **fondo transparente real** o, si la herramienta no lo permite, con **verde puro #00FF00** para recortarlo después.

**Leyenda:** 🟢 se reemplaza sin tocar código (mismo nombre y tamaño) · 🟡 requiere un cambio pequeño de código para usarlo · ✅ entregado e integrado.

Los fondos de diálogo entregados el 31-10-2026 (calle, tutoría, patio al atardecer, calle al atardecer, sala y cuarto de noche) ya se usan: el juego elige la versión de atardecer o de noche al volver del colegio. Las calles de día y de atardecer todavía no aparecen en ninguna escena, porque en la calle no hay diálogos; quedan listas para cuando se agreguen.

## Resumen

| # | Asset | Archivo | Estado actual | Integración |
|---|---|---|---|---|
| 1 | Profesor tutor · hoja de mapa | `assets/characters/tutor_directions.png` | **Entregado e integrado** | ✅ |
| 2 | Fondo VN · calle de día | `assets/vn/street.png` | **Entregado e integrado** | ✅ |
| 3 | Fondo VN · oficina de tutoría | `assets/vn/tutor_office.png` | **Entregado e integrado** | ✅ |
| 4 | Mapa · oficina de tutoría | `assets/world/tutor_office_map.png` | **Entregado e integrado** (colisiones y tutor ajustados) | ✅ |
| 5 | Fondo VN · patio al atardecer | `assets/vn/courtyard_sunset.png` | **Entregado e integrado** | ✅ |
| 6 | Fondo VN · calle al atardecer | `assets/vn/street_sunset.png` | **Entregado e integrado** (v2, misma calle que la de día) | ✅ |
| 7 | Fondo VN · sala de noche | `assets/vn/living_night.png` | **Entregado e integrado** | ✅ |
| 7b | Fondo VN · sala de día igual a la de noche | `assets/vn/living.png` | El de día es otra sala | 🟢 |
| 8 | Fondo VN · cuarto de noche | `assets/vn/bedroom_night.png` | **Entregado e integrado** · el de día está en [prompts del cuarto](PROMPTS_CUARTO_SOFI_v0_42.md) | ✅ |
| 9–11 | Expresiones de Camila, Bruno y Sebas | `assets/vn/*_worried_v4.png`, `sebas_tired_v4.png` | Solo cara neutra | 🟡 |
| 12 | Ciclos de caminata (6 personajes) | `assets/characters/*_walk.png` | Movimiento simulado | 🟡 |

---

## Sprites de personajes

### 1. Profesor tutor · hoja de mapa en cuatro vistas ✅

> Entregada por el equipo e integrada. El prompt se conserva como referencia para regenerarla.

- **Archivo:** `assets/characters/tutor_directions.png`, cuadrado (1254×1254 como Mateo y Camila), transparente.
- **Se ve en:** el mapa de tutoría, junto a la puerta.
- **Referencias:** imagen 1 `assets/characters/mateo_directions_v4.png` (diseño y estilo pixel); imagen 2 `assets/vn/tutor_v2.png` (identidad).

```text
Use case: illustration-story. Asset: transparent 2x2 sprite sheet for top-down RPG with exactly four full-body chibi pixel-art views of the SAME adult teacher. Image1 is layout/pixel style reference only, image2 is the identity: adult Peruvian man in his 40s, short messy salt-and-pepper hair that is mostly silver grey, thin rectangular dark glasses, warm brown skin, gentle smile, forest-green knit V-neck cardigan with brown buttons over cream collared shirt, brown belt, khaki trousers, dark brown shoes, closed blue folder held under his right arm. Slightly taller and broader than the teen sprites but same chibi big-head proportions. Four EQUAL square cells, TOP LEFT front/down, TOP RIGHT back/up, BOTTOM LEFT left-facing profile, BOTTOM RIGHT right-facing profile. Every sprite centered at same baseline within its cell, standing upright, level head, other arm relaxed. Match four views scale. Keep 15% transparent padding in each cell, no parts cross cell boundaries, no grid lines, no labels no text, true transparent background. Square overall sheet.
```

> Ya existen dos vistas generadas con FLUX.2 Klein (frente y espalda), de buena calidad y con fondo verde, en la carpeta temporal de esta sesión. Si se generan las vistas por separado, este prompt por vista funciona bien con fondo verde:
>
> ```text
> A single small pixel art game sprite of a friendly adult Peruvian male school teacher in his 40s, chibi proportions with big head and short body, full body, [standing facing the viewer, front view | seen from behind, back view, face not visible | full side profile facing left | full side profile facing right], idle pose, short messy salt-and-pepper hair that is mostly silver grey, thin rectangular glasses, warm brown skin, forest-green V-neck cardigan over cream collared shirt, khaki trousers, dark brown shoes and blue folder under his arm. Authentic 16-bit RPG pixel art sprite, top-down RPG character, crisp dark 1-pixel outline, flat two-tone shading, limited palette, visible individual pixels, hard pixel edges, no anti-aliasing, solid bright green screen background #00FF00, isolated character, centered, no text, no shadow, no other characters
> ```
>
> Usar la **misma semilla** en las cuatro vistas. La vista derecha puede ser el espejo de la izquierda.

### 9–11. Expresiones para mostrar consecuencias 🟡

Hoy solo Mateo y Sofi cambian de cara según la escena. Las decisiones del recreo afectan a Camila, Bruno y Sebas, pero ellos siempre se ven neutros.

- **Archivos:** `assets/vn/camila_worried_v4.png`, `assets/vn/bruno_worried_v4.png`, `assets/vn/sebas_tired_v4.png`; 1024×1536, transparentes.
- **Referencia:** el sprite neutro del mismo personaje (`camila_v4.png`, `bruno_v4.png`, `sebas_v4.png`), para identidad, ropa y encuadre.
- **Código:** añadir las claves a `ConversationUI.SPRITES` y asignarlas en `Main._scene_sprite_key` (por ejemplo, `D2_A`/`D3_A2` para Camila, `D3_C2`/`D4_C2` para Bruno, `D2_C` para Sebas).

```text
Use case: illustration-story. Asset: transparent anime visual-novel character sprite, same framing as the reference: head to upper thighs, entire hair and both hands visible, generous transparent margin. Reference image is the SAME character's identity, face, hairstyle, outfit and art style: keep everything identical except expression and pose. [EXPRESSION]. Clean detailed anime school-VN linework matching the reference. Actual transparent background, no glow, no frame, no text, one person only.
```

Sustituir `[EXPRESSION]` por:

- **Camila preocupada:** `Camila looks worried and uneasy: eyebrows raised together, eyes looking slightly down to the side, lips pressed, one hand holding her other forearm close to her body, shoulders a little hunched.`
- **Bruno preocupado:** `Bruno looks concerned and regretful: brows drawn together behind his glasses, small frown, gaze lowered, holding his book against his chest with both arms, head slightly tilted down.`
- **Sebas cansado:** `Sebas looks tired and drained: heavy half-closed eyelids, faint dark circles under the eyes, small weak smile, one hand rubbing the back of his neck, shoulders slumped.`

### 12. Ciclos de caminata 🟡

Hoy el paso se simula con rebote y balanceo por código. Para una animación real se necesita una hoja por personaje: Sofi, Mateo, Camila, Bruno, Sebas y el profesor tutor.

- **Archivos:** `assets/characters/<nombre>_walk.png`, 4 columnas × 4 filas de celdas cuadradas iguales, transparente.
- **Referencia:** la hoja 2×2 del personaje (`*_directions*.png`).
- **Código:** `World._draw_character` debe elegir columna según el tiempo y fila según la dirección.

```text
Use case: illustration-story. Asset: transparent pixel-art WALK CYCLE sprite sheet for a top-down RPG of the SAME character as the attached 2x2 sprite sheet: identical identity, outfit, palette, pixel density, chibi proportions, dark outline and scale. Exactly 4 columns x 4 rows of EQUAL square cells. Columns are walk frames: contact, passing, contact (opposite leg), passing. Rows: row 1 facing down/front, row 2 facing up/back, row 3 facing left, row 4 facing right. Arms swing opposite to legs, slight head bob. Every frame centered with feet on the same baseline, 15% transparent padding per cell, nothing crosses cell boundaries. No grid lines, no labels, no text, true transparent background.
```

---

## Fondos de novela visual (escenas de diálogo)

Todos a **1672×941** (16:9), como los actuales en `assets/vn/`. Referencia de estilo recomendada: `assets/vn/classroom.png`. Al final de la sección se indica el cambio de código.

### 2. Calle de camino al colegio 🟡

- **Archivo:** `assets/vn/street.png`. Hoy la clave `street` de `ConversationUI.BACKGROUNDS` apunta a `courtyard.png`.

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background of a modest safe Peruvian neighborhood street in the morning, camera standing teenager height on the sidewalk. Two- and three-storey painted house fronts with small balconies and flowering plants, a few parked bicycles, low trees, distant hills, soft warm morning light and clear sky, the same warm coherent palette as the reference classroom background. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no cars in foreground, no UI, no text no lettering no signs no watermark, warm coherent polished painterly anime environment.
```

### 3. Oficina de tutoría 🟡

- **Archivo:** `assets/vn/tutor_office.png`. Hoy la tutoría usa el pasillo (`corridor.png`).

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background of a small welcoming school tutoring / counseling office in a modest Peruvian school, camera standing teenager height. Cream and teal walls matching the reference school, a wooden desk with a few folders and a potted plant, two or three comfortable chairs facing each other around a small round table, a bookshelf, a cork board with abstract colorful paper notes (no readable text), a window with soft daylight. Calm, safe and friendly atmosphere. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no UI, no text no lettering no posters with words no watermark, warm coherent polished painterly anime environment.
```

### 5. Patio del colegio al atardecer (despedida) 🟡

- **Archivo:** `assets/vn/courtyard_sunset.png`. **Referencia:** `assets/vn/courtyard.png`, para conservar la misma composición.

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached school courtyard background with the SAME composition, buildings, trees and benches, but at late afternoon sunset after classes: warm orange and pink sky, long soft shadows, golden rim light on buildings and trees, a few lit windows. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no UI, no text no lettering no watermark, warm coherent polished painterly anime environment.
```

### 6. Calle al atardecer (regreso a casa) 🟡

- **Archivo:** `assets/vn/street_sunset.png`. **Referencia:** el nuevo `assets/vn/street.png` (asset 2).

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached neighborhood street background with the SAME composition, houses and plants, but at sunset on the way home: orange and violet sky, warm streetlights just turning on, long soft shadows, cozy lit windows. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no cars in foreground, no UI, no text no lettering no signs no watermark, warm coherent polished painterly anime environment.
```

### 7. Sala y comedor de noche (cena) 🟡

- **Archivo:** `assets/vn/living_night.png`. **Referencia:** `assets/vn/living.png`.

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached family living and dining room with the SAME composition and furniture, but in the evening at dinner time: dark blue night outside the window, warm ceiling lamp and table lamp light, dinner plates and a pot on the dining table, cozy family atmosphere. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no UI, no text no lettering no watermark, warm coherent polished painterly anime environment.
```

### 8. Cuarto de Sofi de noche 🟡

- **Archivo:** `assets/vn/bedroom_night.png`. **Referencia:** `assets/vn/bedroom.png`.

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached teenage girl's bedroom with the SAME composition, lilac and pink decor and furniture, but at night: deep blue sky and moon through the window, warm fairy lights and desk lamp on, soft glow from the computer monitor, calm bedtime mood. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no UI, no readable screen content, no text no lettering no watermark, warm coherent polished painterly anime environment.
```

### 6b. Calle al atardecer, igual a la de día ✅

> Resuelto el 31-10-2026: se entregaron la calle de día y la de atardecer v2 con la misma composición, y ambas están integradas.

El atardecer entregado muestra otra calle (moderna, con pistas anchas) que la de día (casas coloniales de colores). Para que el regreso se lea como el mismo camino, conviene regenerarlo a partir de la de día. **Referencia:** `assets/vn/street.png`.

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached colonial Peruvian neighborhood street with EXACTLY the same camera, colorful houses, balconies, potted plants, trees, bicycle and mountains, but at sunset on the way home from school: orange, pink and violet sky, warm wall lamps just turning on, long soft shadows on the sidewalk, cozy lit windows. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no cars in foreground, no UI, no text no lettering no signs no watermark, warm coherent polished painterly anime environment.
```

### 7b. Sala de día igual a la de noche 🟢

La sala de noche entregada es otra habitación (sala abierta con comedor amplio) que la de día (sala pequeña con cocina al fondo). Como el desayuno y la cena ocurren en el mismo lugar, conviene regenerar la de día a partir de la de noche. **Referencia:** `assets/vn/living_night.png`. **Archivo:** reemplaza `assets/vn/living.png`.

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached Peruvian family living and dining room with EXACTLY the same camera, sofa, armchair, coffee table with woven runner, Andean rug, plants, framed pictures, dining table and chairs, but in the MORNING at breakfast time: bright daylight and blue sky with mountains through the balcony door, lamps off, breakfast on the table (bread, cups of tea, fruit, a small jug), warm sunlight patches on the tiled floor. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no UI, no text no lettering no watermark, warm coherent polished painterly anime environment.
```

**Código para los fondos 2–8 (ya aplicado el 31-10-2026):** añadir las claves a `ConversationUI.BACKGROUNDS` (`street` → `street.png`, `tutor_office`, `courtyard_sunset`, `street_sunset`, `living_night`, `bedroom_night`). En `Main._conversation_background` hay que usar `tutor_office` cuando el lugar es `tutor` y, si `daily.is_evening()`, la variante de atardecer o de noche del lugar.

---

## Mapas explorables

### 4. Oficina de tutoría (mapa) 🟡

- **Archivo:** `assets/world/tutor_office_map.png`, **1774×887** (2:1), como `living_room_map.png`.
- **Se ve en:** el lugar `tutor` de la rutina, al que se llega por la izquierda del colegio. Hoy usa el pasillo `draft_d3`.
- **Referencia:** `assets/world/living_room_map.png` (estilo y perspectiva).
- **Código:** en `World.ROUTINE_BACKGROUNDS` y `ROUTINE_BLOCKS`, añadir `tutor_office` con las colisiones de los muebles. En `DailyRoutine.map_key()`, cambiar `"tutor": "draft_d3"` por `"tutor": "tutor_office"`. El tutor queda en (380, 250); la salida está a la derecha.

```text
Use case: illustration-story. Asset type: playable 2D overhead RPG room background. One wide rectangular welcoming school tutoring / counseling office in a modest Peruvian school, near orthographic top-down 3/4 view looking down on the floor, matching the reference game's clean hand-painted tiles. Cream and teal walls along top edge only, light wooden or tiled floor. Tutor desk with folders and a plant against the top wall slightly left of center, bookshelf and filing cabinet in the top left corner, two small armchairs and a round low table in the top right area, a doorway opening on the RIGHT edge leading back to the school. All furnishings ONLY in top third and outer corners. Keep a large EMPTY contiguous walkable floor across the center and lower half. No people, no lettering no signs no posters with words no UI no arrows, one coherent map.
```

---

## Criterios de aceptación

- Fondos: misma resolución que los actuales, tercio inferior despejado en los de novela visual y área central libre en los mapas.
- Sprites: fondo transparente real o verde puro uniforme, celdas iguales, pies sobre la misma línea base y escala igual a la de Mateo y Camila.
- Ningún texto legible en carteles, pantallas, carpetas ni ropa.
- Mismo nombre de archivo cuando el asset es 🟢. Los 🟡 necesitan el ajuste de código descrito; puedo hacerlo cuando tengas las imágenes.
