# Diálogos y chat · 0.39.0-preview

Aplicación del bloque de diálogos y chat de `Correcciones para el juego.txt`, según la prioridad indicada por el usuario. No cierra la rutina diaria, el rediseño del escritorio, el MOBA sin torres, las transiciones por bordes ni las nuevas poses y caras.

## Comportamiento

- El texto se muestra completo y sigue avanzando automáticamente. Clic izquierdo dentro del recuadro de lectura o Enter adelantan el parlamento sin botón adicional. En chat se puede pulsar el área de mensajes o de escritura. Los botones de historial y las barras de desplazamiento conservan su función.
- Las decisiones no tienen avance automático. El segundo clic de un doble clic no salta otra línea ni escoge por accidente una opción recién aparecida.
- Pausa, Alt Tab y cambio de tamaño de texto durante la pausa conservan el tiempo restante y la posición de lectura de la misma pantalla. Una línea diferente recibe su propio tiempo. No se promete conservar segundos después de cerrar y volver a ejecutar el proceso.
- Los avatares de mensajes mantienen 46×46 píxeles lógicos tanto en grupo como en privado. El texto ocupa el ancho restante y aumenta la altura del mensaje.
- La sala de cómputo del Día 1 usa un fondo interior. Habitación, patio y pasillo toman el fondo del mapa actual. Se conserva el nombre junto al personaje que habla.
- Los parlamentos, opciones e historial se presentan sin punto y coma ni dos puntos. La transformación se hace al mostrar el texto, con punto y mayúscula posterior, para conservar intactas las fuentes recuperadas y los IDs.

## Fondo generado y sustitución

Archivo integrado: `assets/vn/computer_lab.png`, PNG RGB de 1672×941. Modo usado: herramienta integrada imagegen, nueva ilustración con `assets/vn/courtyard.png` como referencia de estilo. Sin transparencia.

Para sustituirlo, entregar un fondo horizontal 16:9 en PNG, al menos 1672×941, de una sala de cómputo escolar vista a la altura de los personajes. Mantener el tercio inferior despejado para la caja y espacio para dos personajes, sin texto, personas ni interfaz. Reemplazar el mismo archivo y reimportar en Godot. El fondo de novela visual no contiene colisiones y no cambia el mapa transitable.

Prompt utilizado:

> Use case: illustration-story. Create one widescreen 16:9 visual novel background of the INSIDE of a Peruvian secondary-school computer lab, using the supplied school courtyard image only as the painterly anime environmental-art style reference and architectural color reference. Eye-level camera at standing teenage character height, NOT top-down, NOT isometric. A believable modest computer classroom: rows of wood desks and black monitors in the middle and rear, simple chairs pushed in, keyboards, large windows admitting warm daylight, cream upper walls and muted teal lower walls matching the reference school, educational posters with no legible text, a whiteboard and ordinary classroom details. Reserve clear open floor and uncluttered space across the front lower third for compositing two standing character sprites and a dialogue box. Computers must be clearly visible behind the character positions on both sides. Human-scale room, warm natural light, crisp polished illustrated game background consistent with an anime visual novel. No people, no characters, no avatars, no UI panels, no text, no logos or watermark. This should unmistakably read as an indoor school computer lab, not the outdoor courtyard.

## Validación

Godot 4.7.2: `RunTests`, `DialogueChatTests`, `CoralRoutesTests`, `AutoPresentationTests` y `MobaReturnTests` aprobados. La nueva suite comprueba conservación del contador, clic, doble clic, opciones, tamaño de avatar, desplazamiento y fondo real de D1, además de pausa durante un guardado pendiente.

`python tests/verify_recovered_script.py` confirma que las fuentes recuperadas siguen intactas. `npm run test:coral-browser` pasa con exportación Web y Chrome, incluyendo clic real, pausa, mensajes largos con texto grande y conversación dentro del laboratorio. Capturas en `build/web/dialogue_*.png`.

## Ejecutable

Preset `Windows Validation`, Windows x86_64, recursos incluidos, guardado local:

`build/windows/Centinela_0.39.0_Dialogos_2026-10-29/Centinela_Dialogos.exe`

El ZIP hermano incluye el ejecutable, instrucciones y manifiesto SHA-256. La versión anterior se conserva. Esta entrega no equivale a la revisión completa de las nuevas correcciones ni a una aprobación académica del contenido.

Exportación release y arranque independiente headless comprobados con salida 0, sin errores de script ni carga. `python scripts/release.py check --channel preview` aprobado. Registros en `build/dialogue-windows-export.log`, `build/dialogue-executable-boot.log` y `build/dialogue-chat-final-tests.log`. El arranque automático no sustituye una partida manual de validación.
