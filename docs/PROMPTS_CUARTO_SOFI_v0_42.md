# Prompts de los assets del cuarto de Sofi · v0.42

El cuarto es el lugar donde empieza y termina cada día: la alarma, la mochila, la PC con Discord y la cama. Hoy combina arte generado con varios muebles **dibujados por código como formas planas**. Este documento da un prompt por cada asset que falta o que conviene rehacer.

Los prompts siguen el formato de `docs/ROUTINE_ASSET_PROMPTS_2026-10-29.json`: en inglés, una imagen por llamada y referencias solo de estilo o identidad. Los props del mapa llevan **fondo transparente real** o, si la herramienta no lo permite, **verde puro #00FF00** para recortarlo.

**Leyenda:** 🟢 se reemplaza sin tocar código · 🟡 requiere un cambio pequeño de código (lo hago cuando estén las imágenes).

## Qué tiene hoy el cuarto

| Elemento | Hoy | Archivo actual |
|---|---|---|
| Fondo del mapa | Arte generado | `assets/world/day0_bedroom.png` (1774×887) |
| Cama, armario, librero, plantas | Props generados | `assets/world/props/*.png` |
| Alarma, mochila, foto, puerta | Objetos generados | `assets/objects/*.png` |
| Sofi durmiendo | Prop generado | `assets/world/props/sofi_sleep.png` |
| **Alfombra, guirnalda de luces, tres cuadros, tocador con espejo, zapatero, TV** | **Formas dibujadas por código** | `World._draw_bedroom_decor()` |
| **PC** | **Recuadro con icono pequeño** | `World._draw_story_target()` |
| Cuarto de noche | Solo un tinte violeta; la ventana sigue mostrando el atardecer | — |
| Fondo de diálogo | Arte generado, **con una mochila en el suelo** | `assets/vn/bedroom.png` (1672×941) |

### Coherencia de paleta

El mapa usa lila y rosa (cama rosa, alfombra lila), que es la identidad pedida para la interfaz. El fondo de diálogo tiene cama turquesa y alfombra andina. Los prompts de abajo unifican el cuarto en **lila, rosa pálido, crema y madera clara, con acentos turquesa** (la chaqueta de Sofi), y conservan los detalles peruanos (alfombra y manta tejidas, fotos de montañas).

## Resumen

| # | Asset | Archivo | Integración |
|---|---|---|---|
| 1 | Alfombra tejida | `assets/world/props/rug.png` | 🟡 |
| 2 | Guirnalda de luces | `assets/world/props/string_lights.png` | 🟡 |
| 3 | Tres cuadros de pared | `assets/world/props/wall_frames.png` | 🟡 |
| 4 | Tocador con espejo | `assets/world/props/vanity.png` | 🟡 |
| 5 | Zapatero | `assets/world/props/shoe_rack.png` | 🟡 |
| 6 | Mueble con TV | `assets/world/props/tv_stand.png` | 🟡 |
| 7 | Escritorio con PC | `assets/world/props/desk_pc.png` | 🟡 |
| 8 | Cama lila (opcional) | `assets/world/props/bed.png` | 🟢 |
| 9 | Fondo del mapa de noche | `assets/world/day0_bedroom_night.png` | 🟡 |
| 10 | Fondo de diálogo de día sin mochila | `assets/vn/bedroom.png` | 🟢 |
| 11 | Fondo de diálogo de noche | `assets/vn/bedroom_night.png` | 🟡 |

---

## Props del mapa (vista RPG desde arriba en 3/4)

**Referencias para todos:** imagen 1 `assets/world/day0_bedroom.png` (perspectiva, luz y estilo pintado); imagen 2 `assets/world/props/bed.png` (acabado de prop aislado).

El tamaño en pantalla es el área que ocupa hoy en el mapa de 768×448. Conviene generar al menos a 6× y conservar la proporción. Al terminar se recorta el borde transparente sobrante.

Prompt base. Se completa con el bloque `[SUBJECT]` de cada asset:

```text
Use case: illustration-story. Asset: one isolated prop for a playable 2D overhead RPG bedroom, near orthographic top-down 3/4 view looking down, matching the reference room's warm clean hand-painted game art, lighting and outline. [SUBJECT] Palette: lilac, pale pink, cream and light wood with small teal accents, cozy teenage girl's room in a modest Peruvian home. Entire object visible, centered, small transparent padding, true transparent background, no floor, no walls, no shadow outside the object, no people, no text no lettering no logos, one object only.
```

### 1. Alfombra tejida 🟡

- **En pantalla:** 300×131 px, centro del cuarto. Generar a 1800×786 px.

```text
[SUBJECT] A large soft oval woven rug lying flat on the floor, seen from above, lilac and pale pink with a cream Andean-inspired geometric border pattern and short cream fringe on the two short ends, flat, slightly textured.
```

### 2. Guirnalda de luces 🟡

- **En pantalla:** franja de unos 436×20 px, en la pared superior. Generar a 2616×120 px.

```text
[SUBJECT] A long horizontal fairy-light garland hanging along a wall in a gentle wave, thin dark wire with evenly spaced small warm glowing bulbs, a few tiny pastel paper stars between bulbs, soft glow halo around each bulb.
```

### 3. Tres cuadros de pared 🟡

- **En pantalla:** 82×27 px sobre la pared, entre el escritorio y el armario. Generar a 984×324 px.

```text
[SUBJECT] Three small framed pictures hanging side by side on a wall, seen almost frontally: light pink frames; inside, simple paintings of Andean mountains at sunset, a llama, and a group of five teenage friends as tiny silhouettes, no faces, no text.
```

### 4. Tocador con espejo 🟡

- **En pantalla:** 60×81 px, pegado a la pared izquierda bajo la cama. Generar a 600×810 px.

```text
[SUBJECT] A small vanity table with a tall rectangular mirror on top, light lilac painted wood, one small drawer with a round knob, on the table a hairbrush, a small plant and two little pastel bottles; mirror shows only a soft light-blue reflection with a diagonal shine, nothing recognizable.
```

### 5. Zapatero 🟡

- **En pantalla:** 64×32 px, abajo a la izquierda. Generar a 768×384 px.

```text
[SUBJECT] A low two-shelf shoe rack in light pink wood seen from above, holding three pairs of shoes: white sneakers, teal sneakers and small brown school shoes, neatly arranged.
```

### 6. Mueble con TV 🟡

- **En pantalla:** 76×60 px, abajo a la derecha. Generar a 760×600 px.

```text
[SUBJECT] A low light-wood TV console with a small flat-screen TV on top; the screen is off and dark with a soft lilac reflection; a game controller and a small plant on the console.
```

### 7. Escritorio con PC 🟡

- **En pantalla:** unos 90×80 px, en la pared superior junto a la cama. Sustituye al recuadro con icono. Generar a 900×800 px. **Referencia adicional:** `assets/objects/pc.png`, para el monitor y la torre.

```text
[SUBJECT] A teenage gamer's study desk against the wall: light wood desk with one computer monitor showing a soft lilac wallpaper glow (no readable content), keyboard with subtle teal backlight, mouse, headset resting on the desk, a small PC tower beside it, a pastel desk lamp, and a teal swivel chair pushed in front of the desk.
```

### 8. Cama lila (opcional) 🟢

- **Archivo:** reemplaza `assets/world/props/bed.png` (1024×1536). Debe coincidir con la manta lila de `sofi_sleep.png`, que se dibuja encima al dormir.
- **Referencia adicional:** `assets/world/props/sofi_sleep.png`, para el color de la manta y el tamaño de la almohada.

```text
[SUBJECT] A single bed seen from above with the headboard at the top: light wood frame, white pillow at the top, smooth lilac blanket with a pale pink woven Andean-pattern throw folded across the foot of the bed, neatly made and EMPTY, no person.
```

---

## Fondos

### 9. Fondo del mapa de noche 🟡

- **Archivo:** `assets/world/day0_bedroom_night.png`, 1774×887.
- **Se ve en:** las etapas `evening`, `bedtime` y `sleep`. Hoy se usa el fondo de día con un tinte.
- **Referencia:** `assets/world/day0_bedroom.png`, con la misma composición exacta para que las colisiones sigan valiendo.

```text
Use case: illustration-story. Asset: playable 2D overhead RPG room background. Recreate the attached bedroom map with EXACTLY the same composition, walls, window, furniture footprint and empty walkable floor, but at night: deep blue night sky and a few stars through the top window, warm wall sconces and fairy lights on, soft lilac and warm amber light pools on the floor, cozy calm bedtime mood. Keep every object in the same position and size. No people, no lettering no signs no UI no arrows, one coherent map.
```

### 10. Fondo de diálogo de día, sin mochila 🟢

- **Archivo:** reemplaza `assets/vn/bedroom.png`, 1672×941.
- **Motivo:** el fondo actual muestra una mochila en el suelo, pero la mochila ahora desaparece del cuarto cuando Sofi la guarda en el inventario.
- **Referencia:** el `assets/vn/bedroom.png` actual.

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached teenage girl's bedroom with the same camera, window with mountain city view, desk with monitor and swivel chair, shelves, framed mountain photos and woven rug, but REMOVE the backpack from the floor (empty floor there) and change the bedding to a lilac blanket with a pale pink woven Andean throw so it matches the game map. Warm morning light. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no UI, no readable screen content, no text no lettering no watermark, warm coherent polished painterly anime environment.
```

### 11. Fondo de diálogo de noche 🟡

- **Archivo:** `assets/vn/bedroom_night.png`, 1672×941.
- **Se ve en:** el chat de la noche, la reacción tras la partida y la hora de dormir.
- **Referencia:** el nuevo `assets/vn/bedroom.png` (asset 10).

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached bedroom with the SAME composition and furniture, no backpack on the floor, but at night: deep blue sky, moon and city lights through the window, curtains half closed, warm bedside lamp and fairy lights on, soft lilac glow from the computer monitor (no readable content), calm bedtime mood. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no UI, no text no lettering no watermark, warm coherent polished painterly anime environment.
```

---

## Integración de código prevista (🟡)

- **Assets 1–6:** sustituir en `World._draw_bedroom_decor()` cada forma plana por `draw_texture_rect` del prop, en el mismo rectángulo. Las colisiones de `DAY0_BLOCKS.bedroom` ya cubren esos muebles.
- **Asset 7:** dibujar `desk_pc.png` para el objetivo `pc` del cuarto en lugar del recuadro con icono; el aro y la flecha del objetivo se mantienen.
- **Asset 9:** elegir `day0_bedroom_night.png` cuando `DailyRoutine.is_evening()` sea verdadero y el lugar sea el cuarto, y quitar el tinte en ese caso.
- **Asset 11:** añadir `bedroom_night` a `ConversationUI.BACKGROUNDS` y usarlo en `Main._conversation_background()` de noche.

## Criterios de aceptación

- Props con transparencia real o verde puro uniforme, sin sombras fuera del objeto y con la misma perspectiva desde arriba que el fondo del mapa.
- Ningún texto legible en pantallas, cuadros ni envases.
- La versión de noche del mapa conserva exactamente la posición de muebles, puerta y ventana.
- Paleta lila, rosa, crema y madera en todo el cuarto, en el mapa y en los diálogos.
