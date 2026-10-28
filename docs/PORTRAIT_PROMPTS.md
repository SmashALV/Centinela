# Prompts de retratos provisionales

Generados con la herramienta integrada **imagegen** el 27-10-2026, con fondo transparente. Son propuestas visuales, no diseños canónicos. Los archivos finales incluidos en el proyecto están en `assets/portraits/`.

## Sofi — `sofi_neutral.png`

> Use case: illustration-story. Asset type: temporary transparent PNG dialogue portrait for the 2D narrative game Centinela 2.0. Subject: Sofi, a fictional 15-year-old Peruvian schoolgirl, shoulders-up, friendly neutral expression, dark wavy shoulder-length hair, casual teal jacket over a plain shirt, fully clothed. Style: cohesive anime-inspired 2D game illustration with crisp contours, restrained flat colors and subtle pixel-art sensibility, suitable for display at 96x96 pixels. Composition: centered single character bust, front three-quarter view, generous clear space around silhouette, no other characters or props. Transparent background with clean alpha edges. Constraints: nonsexualized age-appropriate design, no text, no symbols, no watermark, no border, no background scenery. This is provisional concept art, not a canonical character design.

## Mateo, Camila, Bruno y Sebas

Para cada imagen se usó el retrato de Sofi **solo como referencia de estilo**, con este prompt base:

> Use case: illustration-story. Asset type: temporary transparent PNG dialogue portrait for the 2D narrative game Centinela 2.0. Use the attached Sofi portrait only as a STYLE reference for line quality, flat-color shading, composition and transparency; create a distinct new character, not Sofi. Cohesive anime-inspired 2D game illustration with crisp contours, restrained colors, subtle pixel-art sensibility, suitable at 96x96 pixels. Centered single shoulders-up bust, front three-quarter view, clean alpha edges, no other characters or props. Nonsexualized age-appropriate design, fully clothed. No text, symbols, watermark, border or background. Provisional concept art, not canonical character design.

Se añadió al prompt base una de estas descripciones:

| Archivo | Descripción añadida |
|---|---|
| `mateo_neutral.png` | Subject: Mateo, fictional 15-year-old Peruvian schoolboy, friendly neutral expression, short dark curly hair, navy blue hoodie over a light shirt; noticeably different facial features from Sofi. |
| `camila_neutral.png` | Subject: Camila, fictional 15-year-old Peruvian schoolgirl, lively neutral expression, dark hair in a high ponytail, coral jacket over a light shirt; noticeably different facial features from Sofi. |
| `bruno_neutral.png` | Subject: Bruno, fictional 16-year-old Peruvian schoolboy, calm neutral expression, straight short dark hair with a neat side part, burgundy jacket over a light shirt; noticeably different facial features from Sofi and Mateo. |
| `sebas_neutral.png` | Subject: Sebas, fictional 14-year-old Peruvian schoolboy, cheerful neutral expression, short tousled dark hair, mustard yellow hoodie over a light shirt; noticeably different facial features from Sofi and Mateo. |

En todas las llamadas se solicitó `transparent_background: true`. Estas imágenes se pueden sustituir directamente por PNG transparentes autorizados con los mismos nombres. Para incorporar expresiones definitivas se necesita el arte correspondiente y la asignación aprobada de expresión a cada línea del guion.
