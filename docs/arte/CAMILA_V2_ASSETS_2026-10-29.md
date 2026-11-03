# Camila v2 · recursos y prompts

Generados con la herramienta integrada `image_gen`, con transparencia; se conservaron los originales anteriores. Las ilustraciones están integradas en la novela visual, los chats, la introducción y el mapa.

| Archivo dentro de E:/GODOT/grooming-2 | Uso y reemplazo |
| --- | --- |
| `assets/vn/camila_v2.png` | PNG RGBA 1024×1536, cabeza a muslos, transparente. Reemplazar manteniendo encuadre, cabeza y manos dentro del lienzo y prendas coral/blanco. |
| `assets/portraits/camila_v2.tres` | AtlasTexture del PNG anterior, región (200, 20, 620, 650). Ajustar la región si cambia el encuadre del rostro. No es un PNG independiente. |
| `assets/characters/camila_directions_v2.png` | PNG RGBA 1254×1254, cuatro celdas iguales de 627×627: frente, espalda / izquierda, derecha. Mantener disposición y escala coherente al sustituirlo. |

## Prompt de la ilustración

Use case: illustration-story. Asset: replacement Camila character sprite for an educational Godot visual novel. The supplied image is a style reference and the original Camila design to redesign. Generate ONE clean three-quarter-body sprite (head to mid thighs), portrait canvas, centered, full hair and hands contained, genuine transparent background. Match the polished anime visual novel linework, cel shading, coral red zip hoodie over a plain white T-shirt and blue jeans of the reference. Camila is a 15-year-old Peruvian schoolgirl; age-appropriate everyday clothing. Give her a clearly different identity from Sofi: short dark-brown chin-length bob with a side part and one small coral hair clip, an oval face, rounded nose, clearly visible small freckles across cheeks, olive green eyes and thicker straight eyebrows. Natural friendly attentive expression, relaxed standing pose, one hand loosely holding the hoodie edge, the other relaxed at her side. Avoid the original long ponytail and original face geometry. Neutral daylight. No background, no glow, no dark halo, no text, no logos, no watermark. Maintain consistent head/body proportions of a teenage school character, not an adult fashion model. Output a game-ready illustration with clean alpha edges.

Referencia: `assets/vn/camila_neutral.png`.

## Prompt de la hoja de direcciones

Use case: style-transfer game sprite asset. Image 1 is the EDIT TARGET four-direction chibi pixel-art sprite sheet, its grid and framing must stay the same. Image 2 is the new Camila identity reference. Replace the character in all four cells of image 1 with chibi Camila from image 2: short chin-length dark brown bob, coral side hair clip, green eyes, freckles, coral red hoodie, white shirt, dark pants, white shoes. Do NOT retain the old ponytail. Keep EXACTLY four equal cells arranged 2 columns by 2 rows on a square transparent canvas. Cell top-left: full-body FRONT facing viewer; top-right: full-body BACK; bottom-left: full-body LEFT profile looking left; bottom-right: full-body RIGHT profile looking right. Center each full figure within its cell, equal scale and baseline; generous empty transparent margin and gap so there is no crossover at the central horizontal or vertical grid boundaries. Feet and hair fully contained. Same chunky pixel-art linework, proportions, shading and game-ready look as image 1. One character per cell, four total, no extra poses, no text, no guide lines, no background, no shadow outside character, no halo. Genuinely transparent background, preserve alpha.

Referencias: `assets/characters/camila_directions.png` y `assets/vn/camila_v2.png`.
