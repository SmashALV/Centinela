# Continuidad del Día 0 al Día 1 · 0.30.0-preview

## Causa del salto al menú

El MOBA guardaba `phase=result` y cambiaba a `Main.tscn`, pero `_ready()` de esa escena siempre mostraba el menú de ranuras. El resultado sí estaba guardado; faltaba distinguir la llegada desde el combate del arranque normal de la aplicación.

## Recorrido corregido

Al pulsar **Continuar** tras el combate, el MOBA marca una transición temporal que no se incluye en el guardado. La escena principal abre automáticamente la ranura y presenta la reacción de Camila en el chat grupal. Su único botón, **Continuar**, guarda `d1_interlude_active` y presenta la transición de Sofi como parlamento del Narrador en una escena visual. El siguiente **Continuar** guarda el comienzo del recorrido D1–D4 y abre el mapa del Día 1. Si se cierra el juego en cualquiera de esas dos pantallas, la ranura conserva `phase=result` y reabre la pantalla pendiente.

El interludio reutiliza `connectors.D1_02_A` de `data/narrative/playable_draft_v0_1.json`; ese texto ya no se repite como nota del chat del Día 1. No se alteraron las líneas literales recuperadas. Los conectores, las reacciones y las condiciones de los finales permanecen señalados como borrador provisional hasta contar con una versión aprobada.

La prueba `tests/MobaReturnTests.tscn` termina una partida sintética, cambia a la escena principal y comprueba que aparece el resultado y que el botón de continuación abre la exploración del Día 1 sin pasar por el menú.
