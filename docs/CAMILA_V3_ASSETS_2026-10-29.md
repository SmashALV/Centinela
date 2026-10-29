# Camila v3 · nuevo rostro

Revisión solicitada por el usuario. Recursos creados con la herramienta integrada `image_gen` y alpha transparente, integrados en la novela visual, el avatar, la presentación y el mapa. Se conservaron los recursos v2.

El nuevo rostro tiene mejillas más llenas, mentón redondeado, nariz más ancha, ojos castaños más pequeños, cejas rectas y piel morena cálida. Conserva el cabello corto, el broche coral y la ropa de Camila.

| Archivo en E:/GODOT/grooming-2 | Requisitos para reemplazar |
| --- | --- |
| `assets/vn/camila_v3.png` | PNG RGBA 1024×1536. Mantener cabeza a muslos, manos y cabello dentro del lienzo y fondo transparente. |
| `assets/portraits/camila_v3.tres` | Avatar AtlasTexture del PNG anterior. Región (200, 20, 620, 650); ajustar si cambia el encuadre. |
| `assets/characters/camila_directions_v3.png` | PNG RGBA 1254×1254. Cuadrícula 2×2: frente, espalda / izquierda, derecha. Celdas 627×627. |

## Prompt de ilustración

Use case: precise-object-edit / illustration-story. EDIT TARGET: the attached Camila visual novel sprite. The user requests ANOTHER FACE, a clearly new facial identity. Change only the facial identity and natural skin tone; preserve the exact short dark brown bob, coral hair clip, red hoodie, white shirt, jeans, body pose, hands, illustration style, framing and portrait dimensions. Keep her an age-appropriate 15-year-old Peruvian schoolgirl. Give her a significantly wider, rounder face with soft full cheeks, a rounded broad chin (no pointed V-shaped jaw), a more prominent broad rounded nose, smaller almond-shaped dark brown eyes with modest irises rather than oversized green anime eyes, thick nearly straight eyebrows, and fuller natural lips with a gentle closed-mouth smile. Warm medium brown skin with a few faint freckles. Her expression should look friendly and confident, not glamorous or adult. Make the facial geometry substantially different from the reference rather than merely changing the eyes or hairstyle. Match the reference's polished cel-shaded visual novel artwork. Keep all nonfacial details and proportions unchanged. Genuine transparent background and clean alpha edges. No scenery, halo, text, logos or watermark.

Referencia: `assets/vn/camila_v2.png`.

## Prompt de hoja del mapa

Use case: precise-object-edit game sprite sheet. IMAGE 1 is the edit target, a 2x2 transparent four-direction chibi pixel-art sheet. IMAGE 2 is the new Camila face and skin-tone reference. Update the character in ALL four cells to match the new identity: warm medium-brown skin, round fuller cheeks and broad rounded chin, smaller almond-shaped dark brown eyes, thick straight eyebrows, broader rounded nose, subtle freckles, gentle friendly smile. Preserve image 1's short dark brown bob with coral hair clip, coral red hoodie, white shirt, dark pants, white shoes, pixel-art treatment, full-body proportions and exact grid framing. Update skin on face and visible hands consistently. IMPORTANT equal square 2x2 grid: upper left full FRONT; upper right full BACK; bottom left LEFT profile facing left; bottom right RIGHT profile facing right. Each figure wholly inside its cell and centered at consistent scale, with generous transparent gutters. No cell crossover, no additional figures or poses. Genuine transparent background, clean alpha, no text, guide lines, scenery, watermark or glow.

Referencias: `assets/characters/camila_directions_v2.png` y `assets/vn/camila_v3.png`.
