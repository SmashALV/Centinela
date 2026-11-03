# Rutina, escritorio y combate · 0.40.0-preview

## Recorrido D0–D4

Cada día comienza en la habitación. Sofi revisa sus mensajes, recoge la mochila, pasa por la sala para desayunar, recorre la calle hacia la derecha y llega al colegio. Puede conversar con los cuatro compañeros en cualquier orden y visitar cómputo o tutoría. Después entra a clase por el borde superior.

Una conversación distinta durante la clase termina con la campana escolar. Se sale por abajo, se despide al grupo y se regresa por la calle hacia la izquierda con iluminación de atardecer. En casa, Sofi cena, vuelve a su cuarto, revisa Discord, juega una partida y se acuesta. La animación de descanso pasa de noche a mañana. El día solo cambia al dormir. Después de dormir en D4 se presenta el desenlace.

Los textos de desayuno, clase, despedida y cena cambian según la jornada. Las decisiones y el apoyo de la historia coral siguen disponibles para los cuatro compañeros. La presentación de Kairo y el privado de Mateo del Día 1 ocurren en Discord al llegar a casa. Se conservan las condiciones de los tres finales y los fragmentos recuperados.

Los bordes cambian de escenario sin rectángulos de salida ni pulsar F. Las actividades pendientes bloquean una transición y muestran el objetivo concreto. Las computadoras solo aparecen en la habitación y la sala de cómputo. Las conversaciones usan el fondo correspondiente al lugar actual, incluido el nuevo salón y la sala de la casa.

## Escritorio

Fondo personal lila y rosado, barra superior con hora, Discord, Arena 5v5, archivos, fotos, música y papelera. Los últimos cuatro accesos son decorativos. Discord y Arena abren sus interfaces; el juego se habilita después de cenar y preparar la partida en el chat. Privacidad permanece disponible y en D4 permite realizar bloqueo y privacidad. Se puede apagar la pantalla y seguir recorriendo el cuarto.

Discord permite releer el canal del grupo y cambiar al privado de Mateo. Los mensajes privados se conservan separados del canal. Los seis iconos del escritorio son SVG propios en `assets/ui/desktop/`; el resto de imágenes nuevas se generó con imagegen.

## MOBA

Cinco aliados contra cinco rivales, sin torres ni bases. Se mantienen el obstáculo central, la navegación alrededor de sólidos, proyectiles, habilidades, escudos y reapariciones. El primer equipo en sumar cinco bajas gana inmediatamente. Al cumplirse 60 segundos gana quien tenga más bajas; si las bajas son iguales, hay empate. Una caída se cuenta una sola vez y la inmunidad de reaparición se respeta. El marcador permanece en el HUD.

## Personajes y assets

Nuevas posturas en novela visual para Sofi, Camila, Bruno, Mateo, Sebas y el avatar anónimo de Kairo. Mateo tiene pelo rizado, rostro más largo y mochila; Sebas tiene un rostro más ancho con pecas y pelo corto recto. Se actualizan sus hojas de cuatro vistas para el mapa. Mateo conserva expresiones de preocupación y alarma con su identidad nueva; Sofi tiene su versión atenta y preocupada. Avatares y caras del prólogo usan recortes AtlasTexture de los nuevos dibujos.

Los 18 PNG generados mediante la herramienta integrada `imagegen`, sus rutas finales y prompts completos están en [ROUTINE_ASSET_PROMPTS_2026-10-29.json](../arte/ROUTINE_ASSET_PROMPTS_2026-10-29.json). Las versiones anteriores se conservan. Los recortes se definen en `assets/portraits/*_v4.tres` y `assets/world/props/sofi_sleep.tres`, sin modificar los PNG generados.

Para sustituirlos:

- Personajes: PNG RGBA 1024×1536 con transparencia real, encuadre de cabeza a muslos y rostro en la misma región. Si cambia el encuadre, ajustar los AtlasTexture y el encuadre de ConversationUI. Las variantes emocionales deben conservar identidad y proporciones.
- Mapas: PNG horizontal de aproximadamente 2:1, perspectiva RPG elevada, con las zonas transitables despejadas. Los muebles pintados tienen cuerpos de colisión separados en `World.ROUTINE_BLOCKS`; al cambiar su posición hay que ajustar esos rectángulos.
- Fondos de novela visual y escritorio: PNG horizontal 16:9, sin personas, rótulos ni interfaz pintada. El código superpone personajes, nombres y botones.
- Hojas direccionales: PNG RGBA cuadrado, cuadrícula 2×2 con frente, espalda, izquierda y derecha en ese orden, escala y centro consistentes.
- Campana: `assets/audio/school_bell.wav`, generada de forma reproducible en `scripts/generate_audio.py`. Reemplazar por WAV mono con volumen comparable, sin cambiar el nombre.

## Guardado y compatibilidad

La rutina guarda día, etapa, lugar, escena y parlamento dentro de `flags.routine`. Se valida tanto en Godot como en IndexedDB. Se guarda antes de mostrar el avance. Pausa y Alt Tab conservan el contador del diálogo. Dormir se puede guardar y reanudar; al recargar durante esa animación se reproduce de nuevo antes de avanzar.

Las ranuras anteriores de D0 o historia coral se actualizan al abrirlas, conservando sus decisiones y la conversación activa. Se incorporan al tramo correspondiente de la jornada, sin inventar actividades ya realizadas. Las vistas previas históricas y los finales ya concluidos conservan su recorrido de compatibilidad. Para comprobar la rutina íntegra desde el primer desayuno, usar una ranura nueva o **Rehacer**.

## Pruebas y entrega

`DailyRoutineTests.tscn` recorre D0–D4 con los tres desenlaces, comprueba actividades obligatorias, cuatro compañeros, bordes, ubicación de PC, escena de clase, atardecer, escritorio, retorno de partidas, descanso y restauración del guardado. `RunTests` comprueba combate, quinta baja, empate, reaparición, obstáculos y navegación. `MobaReturnTests` comprueba el cambio real de escena de MOBA a historia y el despertar siguiente. Se mantienen las pruebas de presentación, diálogos y rutas.

`npm run test:coral-browser` comprueba el flujo nuevo en Chrome con teclas y clics, junto con escenas preparadas para la revisión visual. `npm run test:web-storage` valida la rutina y rechaza estados corruptos sin reemplazar el guardado anterior. Las capturas quedan en `build/web/daily_*.png`.

Ejecutable Windows x86_64 con recursos incluidos y guardado local: `build/windows/Centinela_0.40.0_Rutina_2026-10-29/Centinela_Rutina.exe`. El ZIP hermano contiene instrucciones y manifiesto SHA-256. Esta es una versión para validar jugabilidad; la revisión automática no sustituye una partida manual completa ni la revisión docente del contenido.

La entrega mantiene desactivado Supabase. Antes de activar eventos remotos para las cinco partidas diarias hay que ampliar el contrato heredado que admite un único resultado MOBA por ranura. El guardado local de las cinco jornadas sí está implementado y probado.
