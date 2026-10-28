# Presentación de novela visual y retratos expresivos

La interfaz del juego omite etiquetas de producción como «borrador», «prueba» y «vista previa». El estado del contenido sigue documentado en los archivos del proyecto y la protección de publicación sigue activa. Los textos literales recuperados permanecen en sus JSON originales; las reacciones añadidas se guardan como contenido editable en `scripts/Main.gd` y `data/narrative/playable_draft_v0_1.json`.

Las decisiones D0 y D1–D4 guardan la opción al elegirla. La pantalla siguiente muestra la reacción de Bruno, Camila o Mateo. Las escenas D1–D4 presentan un retrato, nombre y parlamento como novela visual; antes de elegir, Sofi y Mateo aparecen juntos. Se conserva el paso de guardado de partidas previas para que puedan reanudarse.

## Variantes generadas

Se usó `image_gen__imagegen` integrado con los retratos neutros existentes como referencias. Todas las salidas son PNG RGBA de 1254×1254 px con transparencia real y están en `assets/portraits/`.

| Archivo | Referencia | Dirección visual del prompt | Uso actual |
|---|---|---|---|
| `mateo_worried.png` | `mateo_neutral.png` | Conservar identidad, encuadre anime de busto, sudadera azul marino y camiseta blanca; expresar preocupación y conflicto interno, fondo transparente | Primeras señales en D2 y conversaciones tensas D3–D4 |
| `mateo_alarmed.png` | `mateo_neutral.png` | Conservar identidad, ropa y encuadre; mostrar alarma ante una petición de encuentro secreto, fondo transparente | D4_01_A y F03 |
| `mateo_relieved.png` | `mateo_neutral.png` | Conservar identidad, ropa y encuadre; mostrar alivio y confianza tras recibir apoyo, fondo transparente | Reacciones de apoyo |
| `sofi_concerned.png` | `sofi_neutral.png` | Conservar identidad, sudadera verde azulado y encuadre; expresar preocupación empática, fondo transparente | Decisiones y diálogo de D3–D4 |

La apariencia de Kairo no está definida en el material recibido: sus mensajes usan el icono del teléfono, sin inventar un rostro. Para arte definitivo hacen falta retratos de Sofi y Mateo con expresiones coherentes en el mismo encuadre, una definición visual aprobada de Kairo si se decide mostrarlo, y una tabla aprobada que asigne expresión a cada parlamento o reacción. Se pueden sustituir los PNG conservando los nombres; si cambian rutas o variantes, actualizar `EMOTION_PORTRAITS` y `_scene_portrait_path()`.

Las reacciones nuevas del grupo D0 son líneas de enlace narrativo, no texto literal recuperado. Para reemplazarlas basta editar `D0_CHAT_REACTIONS` conservando las claves `D0_05_A_OPT_A/B/C`; después ejecutar la verificación de guion, los tests Godot y la prueba Web.
