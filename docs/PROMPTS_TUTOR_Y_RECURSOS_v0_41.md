# Prompts para reemplazar los recursos provisionales v0.41

Los recursos del tutor actuales se dibujaron con `scripts/generate_tutor_assets.py` como marcador de posición. Para que coincidan con el arte del juego, conviene regenerarlos con el mismo flujo de los demás personajes: **imagegen** con fondo transparente, una llamada por archivo y una imagen de referencia **solo para estilo**.

El estilo del juego tiene dos niveles:

- **Novela visual (`assets/vn/*_v4.png`):** ilustración anime escolar con línea limpia y detallada, colores planos con sombreado suave, figura de la cabeza a la parte alta de los muslos, 1024×1536 y fondo transparente. Referencia recomendada: `assets/vn/bruno_v4.png`.
- **Mapa (`assets/characters/*_directions*.png`):** pixel art RPG de cuerpo entero en una cuadrícula 2×2 con contorno oscuro y proporción chibi (cabeza grande), legible a 46×46 px. El orden de las vistas es: arriba izquierda frente, arriba derecha espalda, abajo izquierda mirando a la izquierda y abajo derecha mirando a la derecha. Referencia recomendada: `assets/characters/bruno_directions.png`.

Paleta del tutor, para mantener la identidad entre ambos niveles: cárdigan verde azulado (#3F8F8A), camisa crema, pantalón marrón topo, cordón de identificación mostaza y gafas de montura oscura.

---

## 1. Tutor · sprite de novela visual

**Archivo:** `assets/vn/tutor_v1.png` (1024×1536, PNG transparente)
**Referencia adjunta:** `assets/vn/bruno_v4.png`, solo como estilo.

```text
Use case: illustration-story. Asset: transparent anime visual-novel character sprite for the 2D school game Centinela 2.0. One adult school tutor / counselor, Peruvian man in his late 30s, head to upper thighs, entire hair and both hands visible with generous transparent margin. Reference image is STYLE ONLY (line quality, flat-color shading, proportions, framing); create a distinct new adult character, clearly older than the teen cast. Face: kind and calm, oval face, warm brown skin, short neat dark brown hair with a side part and a few grey strands at the temples, rectangular dark-framed glasses, soft brown eyes, light smile lines, gentle closed-mouth smile. Outfit: teal-green knit cardigan (#3F8F8A) over a cream button shirt, taupe trousers, mustard school lanyard with a blank ID card (no text). Pose: upright frontal, shoulders level, holding a purple folder against his chest with both hands, approachable and non-threatening body language. Clean detailed anime school-VN linework matching the reference. Actual transparent background, no glow, no frame, no text, no logos, one person only. Age-appropriate, professional, fully clothed.
```

**Después de generar:** recortar o escalar a 1024×1536 sin deformar, con la cabeza en el mismo tercio superior que `bruno_v4.png`. Guardar con el mismo nombre para que `ConversationUI.SPRITES.Tutor` lo use sin tocar código.

## 2. Tutor · avatar de chat y consejo

**Archivo:** `assets/portraits/tutor_v1.tres` (recorte de la imagen anterior, no requiere imagen nueva)

Al reemplazar `tutor_v1.png`, ajustar `region` para que el recuadro de 500×500 contenga la cara y los hombros, como en `assets/portraits/bruno_v4.tres` (`Rect2(265, 10, 530, 530)`). El valor actual es `Rect2(262, 170, 500, 500)`. Si la cabeza queda más arriba en la nueva ilustración, reducir el segundo número.

Si se prefiere un retrato independiente, como los de `docs/PORTRAIT_PROMPTS.md`:

```text
Use case: illustration-story. Asset type: transparent PNG dialogue portrait for the 2D narrative game Centinela 2.0. Use the attached tutor sprite only as reference for identity and style. Subject: the school tutor, adult Peruvian man in his late 30s, shoulders-up, kind calm expression, short neat dark brown hair with grey at the temples, rectangular dark glasses, teal-green cardigan over cream shirt, mustard lanyard. Cohesive anime-inspired 2D game illustration with crisp contours and restrained flat colors, readable at 96x96 pixels. Centered single bust, front three-quarter view, clean alpha edges. No text, symbols, watermark, border or background.
```

## 3. Tutor · hoja de mapa en cuatro vistas

**Archivo:** `assets/characters/tutor_directions.png` (PNG transparente, cuadrícula 2×2 de celdas cuadradas)
**Referencias adjuntas:** `assets/characters/bruno_directions.png` (estilo y escala) y el nuevo `assets/vn/tutor_v1.png` (identidad y ropa).

```text
Use case: game sprite sheet. Transform the attached tutor character into a transparent pixel-art full-body sprite sheet for a top-down 2D RPG, matching the attached teen sprite sheet EXACTLY in pixel density, chibi proportions (large head, short body), dark outline, shading style and character scale. Four views in a 2x2 grid of equal square cells: top-left facing down/front, top-right facing up/back, bottom-left facing left, bottom-right facing right. Same character in every view: adult man, slightly taller and broader than the teen sprites, short neat dark brown hair with grey temples, rectangular dark glasses (visible in front and side views), teal-green cardigan (#3F8F8A) over cream shirt, mustard lanyard with small blank card, taupe trousers, dark brown shoes. Idle standing pose, arms relaxed. Orthographic RPG perspective, readable silhouette at 46x46 px. Transparent background, no text, no shadows on the ground, no other characters, no grid lines.
```

**Después de generar:** comprobar que cada vista esté centrada en su cuadrante y que los cuatro cuadrantes sean del mismo tamaño. `World.gd` divide la imagen en cuatro partes iguales.

## 4. Opcional · profesor de la clase

La clase tiene ahora líneas del **Profesor**, que se presentan sin ilustración, solo con su nombre. Si se quiere mostrarlo:

**Archivo sugerido:** `assets/vn/profesor_v1.png` (1024×1536). Después hay que añadir `"Profesor"` a `ConversationUI.SPRITES`.

```text
Use case: illustration-story. Asset: transparent anime visual-novel character sprite for the 2D school game Centinela 2.0. One adult classroom teacher, Peruvian woman in her 40s, head to upper thighs, both hands visible, generous transparent margin. Reference is STYLE ONLY; distinct new adult character, clearly different from the tutor. Face: friendly and attentive, shoulder-length black hair tied low, small earrings, warm smile. Outfit: navy blazer over a light lilac blouse, dark grey trousers. Pose: frontal, one hand holding a whiteboard marker at chest height, the other holding an open notebook. Clean detailed anime school-VN linework matching the reference. Actual transparent background, no glow, no frame, no text, no logos, one person only.
```

## 5. Opcional · ciclo de caminata de los compañeros

Hoy, caminar y moverse en reposo se simula por código (rebote, balanceo, saltito y cambio de vista). Para una animación real de pasos se necesita una hoja por personaje:

**Archivo sugerido:** `assets/characters/<nombre>_walk.png`, 4 columnas (fotogramas) × 4 filas (abajo, arriba, izquierda, derecha). Requiere adaptar `World._draw_character` para elegir el fotograma.

```text
Use case: game sprite sheet. Using the attached 2x2 sprite sheet of <NAME> as exact reference for identity, outfit, palette, pixel density and scale, create a transparent pixel-art WALK CYCLE sheet for a top-down 2D RPG: 4 columns (walk frames: contact, passing, contact, passing) by 4 rows (row 1 facing down, row 2 facing up, row 3 facing left, row 4 facing right). Equal square cells, character centered in every cell with feet on the same baseline, arms swinging opposite to legs. Same chibi proportions and dark outline as the reference. Transparent background, no text, no ground shadow, no grid lines.
```

Sustituir `<NAME>` por Sofi, Mateo, Camila, Bruno, Sebas o Tutor y adjuntar su hoja `*_directions*.png`.

---

### Criterios de aceptación

- Fondo realmente transparente (alfa), sin halo blanco alrededor de la silueta.
- El tutor se distingue a primera vista de los cinco adolescentes: más alto, con gafas, canas y cordón mostaza.
- Ningún texto legible en tarjetas, carpetas ni ropa.
- Los mismos nombres de archivo y tamaños, para que el reemplazo no requiera cambios de código (excepto en los opcionales 4 y 5).
