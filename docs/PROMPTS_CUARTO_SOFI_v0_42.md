# Cuarto de Sofi y fondos del recorrido · revisión y prompts v0.42

> **Estado al 31-10-2026: cuarto completo.** Ya están integrados el mapa de día (`assets/world/bedroom_map.png`) y el de noche (`assets/world/bedroom_map_night.png`), que coinciden borde a borde y solo cambian la ventana y la luz, y el fondo de diálogo de día definitivo (`assets/vn/bedroom.png`, la versión cuya composición sigue al cuarto de noche). El juego usa claves de mapa propias (`sofi_room` y `sofi_room_night`) con colisiones nuevas, cama resaltada completa, PC junto al escritorio, fotos sobre él, mochila en el suelo y Sofi dormida girada sobre la cama. Los muebles dibujados por código ya no aparecen en la rutina; el cuarto antiguo del Día 0 se conserva solo para partidas anteriores a la rutina.

## Revisión de la entrega del 31-10-2026

Criterios del juego que se usaron para revisar:

- **Mapas:** vista RPG desde arriba en 3/4, estilo pintado y piso central libre.
- **Fondos de diálogo:** 1672×941, tercio inferior despejado y coherentes con la versión de día y de noche del mismo lugar.
- **Props:** transparencia real, la misma perspectiva desde arriba del mapa y el mismo acabado pintado.
- **En todos:** ningún texto legible.

| # | Imagen | Veredicto | Motivo |
|---|---|---|---|
| 16 | Mapa del cuarto (noche) | ✅ **Procede** · pendiente su versión de día | Excelente: misma vista y estilo que el mapa de tutoría, ya trae cama, escritorio, armarios, alfombras, polaroids y luces pintados. Guardado en `assets/world/bedroom_map_night.png`. No se activa hasta tener la versión de día con la misma composición; si no, el cuarto cambiaría de muebles entre la mañana y la noche |
| 17 | Mapa de tutoría | ✅ **Integrado** | Coherente con la oficina de diálogo v2. Se ajustaron colisiones, puerta de salida a la derecha y el tutor delante de su escritorio |
| 18 | Diálogo · cuarto de noche v2 | ✅ **Integrado** (reemplaza a la v1) | Coincide con el mapa 16 (silla rosa, cojín de flor, repisa bajo la ventana) y ya no tiene bolsa en el suelo |
| 22 | Diálogo · tutoría v2 | ✅ **Integrado** (reemplaza a la v1) | Mismos sillones, mesa redonda y escritorio que el mapa 17 |
| 20 + 23 | Diálogo · calle de día y al atardecer v2 | ✅ **Integradas** (reemplazan a las v1) | Ahora son la misma calle a dos horas distintas. Resuelve la incoherencia anterior |
| 19 | Diálogo · sala de noche v2 | ⚪ **No hace falta** | La v1 integrada conserva la alfombra y el camino de mesa andinos de la sala de día y del mapa. La v2 pierde esa identidad y tiene una planta tapando la esquina inferior izquierda |
| 21 | Diálogo · patio al atardecer v2 | ⚪ **No hace falta** | La v1 integrada se parece más al patio de día (corredor con columnas turquesa). La v2 es válida, pero es otro patio |
| 9 | Escritorio con PC | ⚪ No hace falta · ❌ si se usara, rehacer | Buen acabado y transparencia, pero vista frontal, no desde arriba. El mapa 16 ya lo incluye |
| 10 | Mueble con TV | ⚪ No hace falta · ❌ si se usara, rehacer | Vista frontal. El mapa 16 no tiene TV y no la necesita |
| 11 | Puf | ❌ Rehacer o descartar | Sin transparencia (fondo crema) y estilo de render 3D fotorrealista |
| 12 | Tocador | ❌ Rehacer o descartar | Sin transparencia, vista frontal y estilo de ilustración vectorial plana, distinto del juego |
| 13 | Polaroids | ⚪ No hace falta | Buen estilo, pero con la pared pintada detrás (sin transparencia). El mapa 16 ya tiene polaroids |
| 14 | Guirnalda de luces | ❌ Rehacer o descartar | La transparencia es falsa: trae una mancha de pared borrosa pixelada alrededor |
| — | Diálogo · cuarto de día (`Dormitorio pastel bañado por el sol2`) | ✅ **Integrado** como `assets/vn/bedroom.png` | Misma paleta e identidad que el cuarto de noche v2, luz de mañana, sin mochila y con el tercio inferior despejado |
| 24 | Mapa del cuarto de día (`Dormitorio pastel bañado por el sol.png`) | ❌ **Rehacer** | Buen estilo, pero: (1) mide 1536×1024 (3:2) y el área de mapa del juego es 2,09:1, así que se perdería el 28 % inferior con el puf y la TV; (2) no coincide con el mapa de noche 16 (cama individual frente a doble, puerta a media pared frente a arriba, tocador, puf y TV que de noche no existen). Día y noche deben ser el mismo cuarto porque comparten colisiones |
| 15 | Alfombra | ⚪ No hace falta · ❌ si se usara, rehacer | Fondo blanco sin transparencia y textura fotorrealista. El mapa 16 ya trae dos alfombras |

**Conclusión:** con el mapa 16, el cuarto ya no necesita props sueltos. Los muebles que el código dibuja como formas planas desaparecerán al activar el mapa nuevo. El fondo de diálogo de día ya está integrado. **Solo falta una imagen: el mapa del cuarto de día**, con el formato y la composición del mapa de noche.

---

## Lo que falta

**Leyenda:** 🟢 se reemplaza sin tocar código · 🟡 requiere un ajuste de código que hago al recibir la imagen.

### 1. Mapa del cuarto de día 🟡 · prioridad alta

- **Archivo:** `assets/world/bedroom_map.png`, **1672×941 (16:9)**, igual que el de noche. Un formato más alto (por ejemplo, 3:2) pierde la parte inferior en el juego.
- **Referencia:** `assets/world/bedroom_map_night.png`. Adjuntarla como **imagen de entrada para editar** (cambio de iluminación) y no solo como referencia de estilo: así la herramienta conserva la distribución.
- **Comprobación rápida:** superponer el resultado sobre el de noche; cama, escritorio, armarios, puerta y plantas deben caer en el mismo lugar.
- **Al recibirlo:** activo los dos mapas (día y noche), rehago las colisiones de los muebles nuevos, recoloco la cama, la PC, la foto y la mochila en sus lugares y quito los muebles dibujados por código.

```text
Use case: illustration-story. Asset: playable 2D overhead RPG room background. Recreate the attached teenage girl's bedroom map with EXACTLY the same camera, room outline, walls, window, door on the right, and every piece of furniture in the same position and size (bed with lilac blanket and flower cushion on the left, bedside table and lamp, fairy lights and polaroid photos on the wall, white cabinets and bookshelf, low bookshelf under the window with lilac curtains, white desk with monitor and pink office chair on a round rug at the top right, tall white wardrobe, potted plants in the corners, empty wooden floor), but in the MORNING: bright soft daylight and blue sky through the window and the left side windows, warm sunlight patches on the floor, fairy lights and lamps off, monitor dark. Only change the lighting and time of day: do not add, remove, move or resize any furniture, and keep the same 16:9 framing. Keep the large central floor EMPTY and walkable. No people, no lettering no signs no UI no arrows, one coherent map.
```

### 2. Fondo de diálogo del cuarto de día ✅ · integrado el 31-10-2026

> Se usó `Dormitorio pastel bañado por el sol2`. El prompt se conserva como referencia.

- **Archivo:** reemplaza `assets/vn/bedroom.png`, 1672×941.
- **Motivo:** el actual es otro cuarto (cama turquesa, alfombra andina) y tiene una mochila en el suelo.
- **Referencia:** `assets/vn/bedroom_night.png` (la v2 ya integrada).

```text
Use case: illustration-story. Asset: 16:9 eye-level anime visual-novel background. Recreate the attached teenage girl's bedroom with EXACTLY the same camera, composition, furniture and decor (bed with cream and lilac bedding, flower-shaped cushion and lilac fringed throw, white nightstand and lamp, polaroid photo wall with fairy lights, hanging plants, lilac curtains, low bookshelf under the window, white bookcase, white desk with drawers, monitor and pink office chair, white wardrobe, white shaggy rug, pink floor cushion, potted plant in the foreground corner), but in the MORNING: bright soft daylight and blue sky with a few clouds over the city and mountains through the window, curtains open, fairy lights and lamps off, warm sunlight patches on the floor and rug, monitor showing only a soft pastel wallpaper with no readable content. No backpack or bag anywhere. Keep foreground lower third open and unobstructed to composite two standing characters and dialogue box. NO people, no UI, no text no lettering no watermark, warm coherent polished painterly anime environment.
```

### 3. Sala de día igual a la de noche 🟢 · prioridad media

Sigue pendiente, como se indica en [PROMPTS_ASSETS_RECORRIDO_v0_42.md](PROMPTS_ASSETS_RECORRIDO_v0_42.md), sección 7b. La referencia es la sala de noche v1 integrada (`assets/vn/living_night.png`).

---

## Si más adelante se quieren props sueltos

No hacen falta con el mapa nuevo. Si alguno se pidiera, debe cumplir:

- **Vista desde arriba en 3/4**, como los muebles del mapa, y no vista frontal.
- **Transparencia real** (canal alfa), sin pared ni fondo pintado detrás y sin halos ni bordes borrosos.
- **Acabado pintado** como el de los mapas: ni render 3D fotorrealista ni ilustración vectorial plana.

Prompt base para cualquiera de ellos, usando el mapa del cuarto como referencia:

```text
Use case: illustration-story. Asset: one isolated prop for a playable 2D overhead RPG bedroom, near orthographic top-down 3/4 view looking down exactly like the furniture in the attached room map, same warm hand-painted game art, lighting and outline. [DESCRIBE THE OBJECT]. Entire object visible, centered, small padding, TRUE transparent background (alpha channel), no wall or floor behind it, no shadow outside the object, no glow halo, no people, no text, one object only.
```
