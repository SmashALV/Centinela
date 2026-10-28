# Continuidad del Día 0 al Día 1 · 0.30.0-preview

## Causa del salto al menú

El MOBA guardaba `phase=result` y cambiaba a `Main.tscn`, pero `_ready()` de esa escena siempre mostraba el menú de ranuras. El resultado sí estaba guardado; faltaba distinguir la llegada desde el combate del arranque normal de la aplicación.

## Recorrido corregido

Al pulsar **Continuar** tras el combate, el MOBA marca una transición temporal que no se incluye en el guardado. La escena principal abre automáticamente la ranura y presenta el resultado con la reacción provisional de Camila. **Continuar historia · Día 1** guarda el comienzo del recorrido D1–D4 y abre el mapa del Día 1. Si se cierra el juego antes de continuar, la ranura conserva `phase=result` y puede reabrirse desde el menú.

El enlace narrativo al Día 1 reutiliza `connectors.D1_02_A` de `data/narrative/playable_draft_v0_1.json`. No se alteraron las líneas literales recuperadas. Los conectores, las reacciones y las condiciones de los finales permanecen señalados como borrador provisional hasta contar con una versión aprobada.

La prueba `tests/MobaReturnTests.tscn` termina una partida sintética, cambia a la escena principal y comprueba que aparece el resultado y que el botón de continuación abre la exploración del Día 1 sin pasar por el menú.
