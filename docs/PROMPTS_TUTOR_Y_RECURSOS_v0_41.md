# Prompts de arte del profesor tutor y recursos v0.41

El **profesor tutor** ya tiene ilustración definitiva entregada por el equipo: `assets/vn/tutor_v2.png` (1024×1536, fondo transparente). Es el mismo docente que dicta la clase (`Profesor`) y atiende la tutoría (`Tutor`). Su avatar `assets/portraits/tutor_v2.tres` es un recorte de esa ilustración (`Rect2(262, 40, 500, 500)`).

La hoja de mapa actual (`assets/characters/tutor_directions.png`) es pixel art generado por `scripts/generate_tutor_assets.py` con la paleta de la ilustración. Para que su acabado iguale al de los compañeros, se puede regenerar con **imagegen** usando el prompt de la sección 1.

El estilo del juego tiene dos niveles:

- **Novela visual (`assets/vn/*_v4.png`, `tutor_v2.png`):** ilustración anime escolar con línea limpia y detallada, colores planos con sombreado suave, figura de la cabeza a la parte alta de los muslos, 1024×1536 y fondo transparente.
- **Mapa (`assets/characters/*_directions*.png`):** pixel art RPG de cuerpo entero en una cuadrícula 2×2 con contorno oscuro y proporción chibi (cabeza grande), legible a 46×46 px. El orden de las vistas es: arriba izquierda frente, arriba derecha espalda, abajo izquierda mirando a la izquierda y abajo derecha mirando a la derecha. Referencia recomendada: `assets/characters/bruno_directions.png`.

Paleta del profesor, tomada de su ilustración: cabello gris oscuro con mechones claros, gafas rectangulares de montura metálica oscura, cárdigan verde bosque (#224830) con botones marrones, camisa crema con cuello (#FAEACE), cinturón marrón, pantalón caqui (#A68A64), zapatos marrón oscuro y carpeta azul (#274296).

---

## 1. Profesor tutor · hoja de mapa en cuatro vistas

**Archivo:** `assets/characters/tutor_directions.png` (PNG transparente, cuadrícula 2×2 de celdas cuadradas iguales)
**Referencias adjuntas:**
1. `assets/vn/tutor_v2.png`: identidad, ropa y colores.
2. `assets/characters/bruno_directions.png`: estilo de pixel art, proporción y escala.

```text
Use case: game sprite sheet. Create a transparent pixel-art full-body sprite sheet for a top-down 2D school RPG of the adult teacher shown in reference image 1, drawn EXACTLY in the pixel style of reference image 2 (same pixel density, chibi proportions with large head and short body, dark 1-px outline, soft two-tone shading, same character scale and baseline). Four views in a 2x2 grid of equal square cells: top-left facing down/front, top-right facing up/back, bottom-left facing left, bottom-right facing right. Keep his identity in every view: adult Peruvian man in his 40s, slightly taller and broader than the teen sprites, messy short dark-grey hair with lighter grey streaks, rectangular thin dark-metal glasses (visible in front and side views), warm brown skin, gentle smile. Outfit: forest-green knit V-neck cardigan with brown buttons over a cream collared shirt, brown belt, khaki trousers, dark brown shoes. He holds a closed blue folder tucked under his right arm in every view (on the far side when seen from the back). Idle standing pose, other arm relaxed. Orthographic RPG perspective, readable silhouette at 46x46 px. Actual transparent background, no text, no ground shadow, no other characters, no grid lines, no frame.
```

**Después de generar:**
- Comprobar que cada vista esté centrada en su cuadrante y que los cuatro cuadrantes midan lo mismo. `World.gd` divide la imagen en cuatro partes iguales.
- Si la figura queda más grande que la de Bruno, reducirla dentro de su celda hasta igualar su altura relativa.
- Guardar con el mismo nombre. Si después se vuelve a ejecutar `scripts/generate_tutor_assets.py`, la hoja se sobrescribe: en ese caso conviene quitar la línea que guarda `tutor_directions.png`.

## 2. Opcional · retrato independiente

Si se prefiere un retrato pintado aparte en lugar del recorte:

```text
Use case: illustration-story. Asset type: transparent PNG dialogue portrait for the 2D narrative game Centinela 2.0. Use the attached teacher illustration as exact reference for identity, outfit and art style. Subject: the same adult teacher, shoulders-up, kind calm smile, messy dark-grey hair with lighter grey streaks, thin rectangular dark glasses, forest-green cardigan over cream collared shirt. Cohesive anime school-VN illustration with crisp contours and soft flat shading, readable at 96x96 pixels. Centered single bust, front three-quarter view, clean alpha edges. No text, symbols, watermark, border or background.
```

## 3. Opcional · ciclo de caminata de los personajes

Hoy, caminar y moverse en reposo se simula por código (rebote, balanceo, saltito y cambio de vista). Para una animación real de pasos se necesita una hoja por personaje:

**Archivo sugerido:** `assets/characters/<nombre>_walk.png`, 4 columnas (fotogramas) × 4 filas (abajo, arriba, izquierda, derecha). Requiere adaptar `World._draw_character` para elegir el fotograma.

```text
Use case: game sprite sheet. Using the attached 2x2 sprite sheet of <NAME> as exact reference for identity, outfit, palette, pixel density and scale, create a transparent pixel-art WALK CYCLE sheet for a top-down 2D RPG: 4 columns (walk frames: contact, passing, contact, passing) by 4 rows (row 1 facing down, row 2 facing up, row 3 facing left, row 4 facing right). Equal square cells, character centered in every cell with feet on the same baseline, arms swinging opposite to legs. Same chibi proportions and dark outline as the reference. Transparent background, no text, no ground shadow, no grid lines.
```

Sustituir `<NAME>` por Sofi, Mateo, Camila, Bruno, Sebas o el profesor tutor y adjuntar su hoja `*_directions*.png`.

---

### Criterios de aceptación

- Fondo realmente transparente (alfa), sin halo blanco alrededor de la silueta.
- El profesor se distingue a primera vista de los cinco adolescentes: más alto, con gafas, cabello gris y carpeta azul.
- Ningún texto legible en tarjetas, carpetas ni ropa.
- Los mismos nombres de archivo y tamaños, para que el reemplazo no requiera cambios de código (excepto en el opcional 3).
