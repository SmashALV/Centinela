# Historia coral jugable · 29-10-2026

Verificación local: Godot 4.7.2, suite general con cero fallos, seis ramas coral con decisiones mediante botones, cinco recorridos heredados, IndexedDB y texto recuperado sin alteraciones. La prueba completa `npm run test:browser` terminó en Chrome sin errores de navegador. La comprobación específica `npm run test:coral-browser` recorrió D0→D1 y capturó exploración, privado de Mateo y novela visual D4. Capturas en `build/web/coral_*.png`.

## Procedencia

El diagrama `Diagrama_guion_acciones_narrador_pistas_v3.png` y los documentos de propuesta v2/v3 entregados por el usuario orientan esta ampliación. `data/narrative/coral_story_v0_1.json` distingue el texto nuevo mediante `source_status: authored_from_user_branching_proposal_pending_review`, `provisional: true` y `ready_for_publication: false`. Los fragmentos `source_scenes` se cargan de los archivos recuperados, sin reescribirlos. La historia nueva no incorpora una rúbrica ni emite puntuación educativa.

## Recorrido

Después del resultado del MOBA, el narrador enlaza D0 con D1. Sofi habla con dos compañeros, entra al lobby y elige A (acuerdos del grupo), B (escuchar a Mateo) o C (seguir jugando). Cada elección muestra una escena propia de D1; B utiliza mensajes privados. D2 tiene una conversación y decisión distinta por ruta. La decisión produce seis desarrollos de D3 y seis escenas de D4. El epílogo combina el final por acción, la ruta y la rama vivida.

Los IDs de decisión del nuevo flujo son `D1_GATE`, `D2_A`, `D2_B`, `D2_C`, `D4_A1`, `D4_A2`, `D4_B1`, `D4_B2`, `D4_C1` y `D4_C2`. En una partida se toman tres de esas decisiones: una de D1, una de D2 y una de D4. Se conservan sus respuestas, las reacciones y los estados de confianza y reparación. Los fragmentos recuperados conservan sus IDs originales y su acceso de compatibilidad.

F01 exige haber iniciado una conversación en la puerta de tutoría, incluso si ocurrió antes de D4. F02 exige haber completado la acción de límite digital con permiso y sin apoyo adulto iniciado. F03 conserva una oferta de acompañamiento si todavía falta ejecutar un paso. Elegir una intención en el diálogo no la convierte por sí sola en acción completada. Ninguna ruta lleva a un encuentro con Kairo.

## Exploración y ayudas

- D0: la foto y el escritorio permiten recordar al grupo y sus acuerdos; el cartel de tutoría identifica apoyo; la PC permite revisar privacidad. Son observaciones opcionales guardadas.
- D1: Sofi habla individualmente con compañeros antes del lobby.
- D2–D3: el objetivo señala al compañero de la ruta; solo se registran hechos realmente presentados. Tutoría sigue disponible.
- D4: después de la conversación, Sofi puede acudir a tutoría, completar un límite en la PC o ir a la salida. Cada acción se guarda antes de mostrar el desenlace.
- `Tab` muestra orientación para navegar, H1 para observar y H2 para comprender. El Día 2 limita la información de H2 hasta que se haya presenciado la escena de la ruta. Las pistas no restan puntos.

`scripts/narrative/CoralStoryFlow.gd` resuelve escenas, objetivos, pistas y final. `scripts/Main.gd` controla la presentación y las interacciones; `scripts/World.gd` sitúa los objetivos. `GameState.coral_state` conserva ruta, rama, decisiones, hechos observados, acciones, estados de compañeros, día, escena, línea, narraciones vistas, pistas solicitadas, apoyo y límite. El guardado Web valida el nuevo estado. Una partida anterior ya iniciada en la ruta v0.3 continúa en ese flujo; una partida que llega ahora al resultado del MOBA entra en la historia coral.

## Duración y comprobación

`python scripts/measure_coral_story.py` cuenta entre **1116 y 1422 palabras visibles en D1–D4**, según ruta y final, incluidas las opciones mostradas. D0, MOBA, lectura de ayudas y exploración añaden tiempo. **No hay todavía una medición cronometrada de una primera partida humana**; 15–20 minutos sigue siendo un objetivo editorial, no una duración verificada. Conviene cronometrar al menos una partida por A, B y C y ajustar el contenido según esos resultados.

`tests/CoralRoutesTests.tscn` recorre las seis ramas, verifica los tres finales, una ayuda condicionada por observación, epílogos y reanudación desde D3. `tests/StoryRoutesTests.tscn` comprueba la continuidad de partidas v0.3. `tests/RunTests.tscn` cubre guardado, D0, mundo y MOBA. `npm run test:web-storage` comprueba el estado Web. `npm run test:browser` verifica la exportación en Chrome; su sección heredada inyecta una ranura v0.3 para probar compatibilidad.
