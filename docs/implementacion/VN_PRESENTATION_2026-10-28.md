# Presentación de novela visual y retratos expresivos

La interfaz del juego omite etiquetas de producción como «borrador», «prueba» y «vista previa». El estado del contenido sigue documentado en los archivos del proyecto y la protección de publicación sigue activa. Los textos literales recuperados permanecen en sus JSON originales; las reacciones y escenas añadidas se guardan como contenido editable en `scripts/Main.gd` y `data/narrative/playable_draft_v0_3.json`.

Las decisiones D0 y D1–D4 guardan la opción al elegirla. La pantalla siguiente muestra la reacción de Bruno, Camila o Mateo. El lobby de D1 ocurre en un canal de grupo; su continuación D1-03 y el mensaje de la skin D2-03 usan un chat privado entre Sofi y Mateo. Las demás escenas D2–D4 presentan a Sofi y Mateo juntos sobre el fondo. Se conservan los guardados de partidas previas para que puedan reanudarse.

## Variantes generadas

Se usó `image_gen__imagegen` integrado con los retratos neutros existentes como referencias. Todas las salidas son PNG RGBA de 1254×1254 px con transparencia real y están en `assets/portraits/`.

| Archivo | Referencia | Dirección visual del prompt | Uso actual |
|---|---|---|---|
| `mateo_worried.png` | `mateo_neutral.png` | Conservar identidad, encuadre anime de busto, sudadera azul marino y camiseta blanca; expresar preocupación y conflicto interno, fondo transparente | Primeras señales en D2 y conversaciones tensas D3–D4 |
| `mateo_alarmed.png` | `mateo_neutral.png` | Conservar identidad, ropa y encuadre; mostrar alarma ante una petición de encuentro secreto, fondo transparente | D4_01_A y F03 |
| `mateo_relieved.png` | `mateo_neutral.png` | Conservar identidad, ropa y encuadre; mostrar alivio y confianza tras recibir apoyo, fondo transparente | Reacciones de apoyo |
| `sofi_concerned.png` | `sofi_neutral.png` | Conservar identidad, sudadera verde azulado y encuadre; expresar preocupación empática, fondo transparente | Decisiones y diálogo de D3–D4 |

La apariencia de Kairo no está definida en el material recibido: desde la versión 0.32 se muestra como un avatar humano anónimo sin rostro identificable. Para arte definitivo hacen falta retratos y sprites de Sofi y Mateo con expresiones coherentes en el mismo encuadre, una definición visual aprobada del avatar de Kairo y una tabla aprobada que asigne expresión a cada parlamento o reacción. Se pueden sustituir los PNG conservando los nombres; si cambian rutas o variantes, actualizar `EMOTION_PORTRAITS` en `scripts/Main.gd` y los mapas de `scripts/ConversationUI.gd`.

Las reacciones nuevas del grupo D0 son líneas de enlace narrativo, no texto literal recuperado. Para reemplazarlas basta editar `D0_CHAT_REACTIONS` conservando las claves `D0_05_A_OPT_A/B/C`; después ejecutar la verificación de guion, los tests Godot y la prueba Web.

## Presentación escénica de la versión 0.32

Las conversaciones presenciales ahora usan `scripts/ConversationUI.gd`: un fondo a nivel de los personajes, dos sprites grandes y una caja inferior con nombre y diálogo. Las elecciones ocupan la caja inferior y dejan a los personajes visibles. D0 en la PC y D1 tienen un panel de canal inspirado en aplicaciones de chat grupal, con barra lateral, avatares y mensajes; no se usa la marca ni el logotipo de Discord. Los mensajes privados que Mateo muestra en D2/D4 aparecen como una tarjeta sobre el escenario. Kairo se representa por un avatar de persona anónima, sin rasgos visibles y sin implicar una apariencia real confirmada.

El cierre del MOBA presenta la respuesta de Camila en ese canal y un único **Continuar** que abre un interludio: el Narrador cuenta qué hace Sofi al día siguiente sobre un escenario con su sprite. Otro **Continuar** inicia el Día 1. La transición se guarda y no se repite como nota del chat. La última línea de cada escena lleva directamente a la siguiente escena o jornada. El prólogo conserva tres pantallas breves: presentación de Sofi, definición del grooming y pautas de prevención.

Los siguientes PNG se generaron con `image_gen__imagegen` integrado y se copiaron a `assets/vn/`. Los sprites son RGBA de 1024×1536 px con fondo transparente; el avatar de Kairo es RGBA de 1374×1145 px; los fondos son RGB de 1672×941 px. No se modificaron los retratos anteriores.

| Archivos | Referencia y dirección del prompt | Sustitución |
|---|---|---|
| `sofi_neutral.png`, `sofi_concerned.png` | Ampliar el retrato de Sofi a pose de cintura; preservar cabello oscuro ondulado y sudadera verde azulado. Variante preocupada y empática, mismo encuadre. | Mantener identidad, ropa, posición y transparencia. |
| `mateo_neutral.png`, `mateo_worried.png`, `mateo_alarmed.png` | Ampliar el retrato de Mateo a pose de cintura; preservar cabello rizado y sudadera azul marino. Variantes preocupado y alarmado, mismo encuadre. | Mantener identidad, ropa, posición y transparencia. |
| `camila_neutral.png`, `bruno_neutral.png`, `sebas_neutral.png` | Ampliar cada retrato existente a pose de cintura conservando rasgos, accesorios y colores diferenciadores. | Mantener cinco identidades coherentes entre retratos y sprites del mundo. |
| `kairo_anonymous.png` | Persona humana con capucha azul oscura, rostro completamente oculto por sombra suave, sin ojos, boca, máscara ni pistas de identidad; tono ambiguo y sin monstruosidad. | Seguir mostrando anonimato hasta que el diseño narrativo establezca su identidad visual. |
| `bedroom.png` | Habitación modesta de adolescente peruana, mañana cálida, cama, mochila y PC, perspectiva a nivel de ojos, espacio central para sprites. | Fondo horizontal 16:9 sin personajes, letras ni interfaz. |
| `courtyard.png` | Patio de colegio peruano contemporáneo, tarde, bancas y plantas, perspectiva a nivel de ojos, espacio para sprites. | Mantener continuidad visual y la zona libre detrás de la caja de diálogo. |
| `corridor.png` | Pasillo escolar peruano tranquilo, luz de tarde y espacio para una conversación íntima. | Mantener continuidad visual y la zona libre detrás de la caja de diálogo. |

**Actualización 0.34:** `ConversationUI.gd` incorpora una vista de mensajes directos con Mateo seleccionado, encabezado privado, mensajes de Sofi y Mateo y respuestas dentro del mismo panel. Los parlamentos marcados `(mensaje)` de D2-03 se agrupan en una tarjeta titulada «CHAT CON KAIRO · compartido por Mateo», para no sugerir que Kairo participa en el chat privado. Antes de explorar D1–D4, el Narrador presenta en dos pantallas la situación y el objetivo; ambas pantallas se guardan y pueden reanudarse. D1-03 añade una conversación no evaluable que desarrolla la relación entre Sofi y Mateo.

Las reglas de selección de variantes están en `_scene_sprite_key()` de `scripts/Main.gd`; las rutas y el tamaño de presentación están en `scripts/ConversationUI.gd`. Al sustituir un PNG, comprobar el modo de color, transparencia y encuadre en Godot y en la exportación Web. La procedencia y el estado provisional del guion siguen documentados fuera de la interfaz del jugador.
