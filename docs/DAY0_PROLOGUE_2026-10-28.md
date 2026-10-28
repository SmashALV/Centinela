# Prólogo del Día 0 · borrador provisional

Al iniciar una ranura nueva, tres pantallas del **Narrador** presentan a Sofía «Sofi» Castillo, sus amistades y el papel del jugador. El tono se inspira en la apertura cálida y directa de los RPG de aventura; el texto es original. La última pantalla conduce al diálogo recuperado de despertar sin alterar el guion literal en `data/narrative/day_0_RECOVERED_PREVIEW.json`.

El texto vive en `PROLOGUE_LINES` de `scripts/Main.gd`. Se puede sustituir allí cuando exista una versión aprobada. `prologue_step` se guarda al avanzar y `prologue_seen` al terminar; al recargar, la ranura abre la pantalla pendiente. Una partida que ya había superado el despertar antes de esta incorporación continúa sin mostrar el prólogo a mitad del recorrido. El prólogo no asigna puntuación educativa ni genera eventos de decisión.

Para una versión definitiva se necesita aprobar el texto, el tratamiento narrativo de Sofi y, si se desea voz, una locución original con derechos de uso. La interfaz actual usa texto y el retrato/fondo existentes, sin requerir nuevos assets.
