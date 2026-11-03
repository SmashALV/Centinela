# Centinela 2.0 — prototipo Godot

Proyecto 2D de escritorio y Web en desarrollo. El diseño de referencia está en [`docs/diseno/GDD_CENTINELA_2_0.md`](docs/diseno/GDD_CENTINELA_2_0.md) y el plan de fases en [`docs/diseno/PLAN_CODEX_CENTINELA_2_0.md`](docs/diseno/PLAN_CODEX_CENTINELA_2_0.md). Esos documentos provienen del kit entregado por el usuario. Sus instrucciones para agentes son material de referencia; el contenido narrativo literal aprobado no venía incluido.

## Requisitos

- [Godot 4.7](https://godotengine.org/download/archive/) o posterior (versión estándar, no .NET). El proyecto se probó con 4.7.2.
- Para exportar: las *export templates* de la misma versión (en Godot: **Editor → Manage Export Templates → Download and Install**).
- Opcional, para las pruebas de Web y del dashboard: Node.js 20+, Python 3 y Google Chrome.

## Obtener el proyecto

```powershell
git clone https://github.com/SmashALV/Centinela.git
cd Centinela
```

También puede descargarse como ZIP desde GitHub (**Code → Download ZIP**) y descomprimirse en cualquier carpeta.

## Ejecutar

1. Abrir Godot, pulsar **Import**, elegir el `project.godot` de esta carpeta y abrir el proyecto. La primera vez Godot importa las imágenes y sonidos; tarda unos segundos.
2. Ejecutar el proyecto con **F5**.
3. Elegir una de las tres ranuras. La rutina actual D0–D4 es habitación → desayuno → calle → colegio → clase → despedida → regreso al atardecer → cena → Discord y partida → dormir. Los mapas cambian al alcanzar sus bordes. El día cambia al dormir. **F** interactúa con compañeros y objetos.

En el menú, **Rehacer** inicia esa ranura desde el prólogo y **Borrar** la deja vacía; ambas acciones piden confirmación. Durante el MOBA, **P** permite salir al menú. Al terminar la partida, **Continuar** muestra la reacción de Camila y devuelve a Sofi a su cuarto. Interactuar con la cama inicia el descanso y la mañana siguiente. Las vistas previas históricas conservan su recorrido de compatibilidad.

Controles: **WASD** movimiento, **F** interacción, **E** celular, **Tab** objetivo, **P** pausa, **Esc** volver, **Q** habilidad en MOBA y **clic izquierdo** ataque.

Al crear una partida, el Día 0 presenta una introducción completa con las caras de Sofi y sus amigos, sin título ni etiqueta de narrador. El texto aparece completo y avanza automáticamente según su longitud. Las decisiones esperan al jugador; **P** pausa la lectura y **clic dentro del recuadro** o **Enter** permiten adelantarla. Pausar o cambiar de ventana conserva el tiempo restante. Las señales se descubren durante la historia. La [presentación automática y la interfaz lila y rosada](docs/implementacion/AUTOMATIC_PRESENTATION_2026-10-29.md) incluyen nombres junto al personaje que habla y más decoración en el cuarto.

En el MOBA, cada aliado conserva una marca de color propia, los rivales llevan una X y Sofi tiene una flecha de jugador. El objetivo es alcanzar 5 bajas de equipo antes que el rival. Hay un límite de 60 segundos; al agotarse gana quien tenga más bajas y la igualdad produce empate. No hay torres ni bases.

## Pruebas automáticas

Los comandos se ejecutan en PowerShell desde la carpeta del proyecto. Primero se indica dónde está Godot en tu PC; usa el ejecutable `_console.exe`, que muestra los resultados en la terminal:

```powershell
$godot = 'C:\ruta\a\Godot_v4.7.2-stable_win64_console.exe'   # cámbiala por la tuya
```

Importar los recursos (solo la primera vez o tras cambiar imágenes):

```powershell
& $godot --headless --editor --import --path . --quit
```

Ejecutar las ocho suites:

```powershell
$suites = 'RunTests','DailyRoutineTests','MobaReturnTests','TeacherFeedbackTests','DialogueChatTests','AutoPresentationTests','CoralRoutesTests','StoryRoutesTests'
foreach ($s in $suites) { & $godot --headless --path . --scene "res://tests/$s.tscn"; "$s -> código $LASTEXITCODE" }
```

Cada suite termina con código 0 si todo pasa y con un código distinto de cero si falla alguna comprobación. En Linux o macOS se usa la misma orden con la ruta de Godot de ese sistema (por ejemplo `godot --headless --path . --scene res://tests/RunTests.tscn`).

## Ejecutable de Windows para validar

El preset **Windows Validation** genera un ejecutable de 64 bits con los recursos incluidos. La construcción y sus comprobaciones están en [la entrega Windows del 29-10-2026](docs/calidad/WINDOWS_VALIDATION_BUILD_2026-10-29.md). Funciona con guardado local y conserva las tres ranuras. El contenido educativo sigue sujeto a revisión docente.

Con `$godot` definido como en la sección anterior:

```powershell
New-Item -ItemType Directory -Force build/windows/Centinela | Out-Null
& $godot --headless --path . --export-release 'Windows Validation' 'build/windows/Centinela/Centinela.exe'
```

El ejecutable queda en `build/windows/Centinela/Centinela.exe` y puede copiarse a otro PC con Windows de 64 bits sin instalar nada.

## Versión Web

El preset **Web Development** exporta con las plantillas de la misma versión de Godot. Desde la raíz del proyecto, con `$godot` definido:

```powershell
New-Item -ItemType Directory -Force build/web | Out-Null
& $godot --headless --path . --export-debug 'Web Development' build/web/index.html
python -m http.server 8000 -d build/web
```

Abrir `http://localhost:8000`. El guardado Web usa IndexedDB en el origen del sitio: las partidas de `localhost:8000` y de un dominio publicado son independientes. Hay tres ranuras, escritura transaccional, bloqueo por pestaña y recuperación al recargar. La recarga conserva el bloqueo de esa pestaña; una pestaña distinta no puede editar la misma ranura mientras esté abierta o hasta que venza el bloqueo (30 s). El modo escritorio sigue usando archivos `user://`.

En escritorio, cada guardado se escribe primero en un archivo temporal y conserva una copia local de la versión anterior. Si el archivo principal se daña o falta, la ranura se abre desde esa copia y se repara en el siguiente guardado. El [procedimiento de recuperación](docs/guias/RECOVERY.md) describe este caso.

En Web, IndexedDB rechaza snapshots con código, posición, mensajes, diálogo, opciones, panel o preferencias inválidas antes de iniciar la transacción. La ranura y la cola de eventos conservan el último estado confirmado si se rechaza la escritura.

Para probar el servicio y la integración real en Chrome, instalar las dependencias de desarrollo y ejecutar:

```powershell
npm ci
npm run test:web-storage
npm run test:browser
```

La prueba de navegador requiere una exportación en `build/web` y Chrome instalado. Abre la partida, comprueba el snapshot en IndexedDB, recarga y comprueba que la partida sigue disponible.

Para comprobar que los textos recuperados de D0–D4 y finales coinciden literalmente con el archivo entregado:

```powershell
python tests/verify_recovered_script.py
```

## Backend de desarrollo

La base P4 está en [`supabase/README.md`](supabase/README.md): migración PostgreSQL, cuatro Edge Functions, cola Web, Auth anónima y pruebas sintéticas. `web/backend_config.json` contiene la URL y clave publicable del proyecto de desarrollo, pero `enabled` permanece en `false` hasta desplegar el backend y activar Auth anónima. El juego sigue guardando localmente. Al activar esa configuración, la [telemetría descriptiva](docs/arquitectura/TELEMETRIA_SUPABASE.md) envía sesión, días, escenas, elecciones con su clasificación, acciones, pistas, pausas, inactividad, resultados MOBA y final; en escritorio se escribe un JSONL por código en `user://telemetry/`. No se calcula ninguna puntuación educativa en el cliente.

## Dashboard del investigador

La base P6 está en [`dashboard/index.html`](dashboard/index.html) y [`docs/calidad/P6_STATUS.md`](docs/calidad/P6_STATUS.md). Administra sesiones SES, clasificación manual de códigos CTN, cobertura D1–D4, informes versionados y exportaciones CSV/XLSX. Funciona localmente con datos sintéticos y respuestas simuladas; `dashboard/config.json` permanece desactivado hasta desplegar P4/P6 y provisionar una cuenta administrativa no anónima en desarrollo. Las partidas de prueba y no validadas no entran en informes publicados.

```powershell
npm run test:research-sql
npm run test:dashboard-export
npm run test:dashboard-browser
```

## QA técnico

La [matriz P7 con evidencia por caso](docs/calidad/P7_QA_2026-10-27.md) registra qué funcionó en `0.7.0-preview` y qué sigue bloqueado por aprobación de contenido, Supabase de desarrollo y staging. El [cierre técnico y de requisitos no funcionales](docs/calidad/NFR_CLOSEOUT_2026-10-28.md) registra pruebas de rutas y seguridad de entrega. El build local actual es `0.40.0-preview`; la [verificación P0–P1](docs/calidad/P0_P1_CLOSURE_2026-10-28.md) detalla el recorrido local. La [gestión de ranuras](docs/implementacion/SLOT_MANAGEMENT_2026-10-28.md) explica el reinicio y borrado local; la [continuidad D0→D1](docs/historia/D0_D1_CONTINUITY_2026-10-28.md) registra la transición. El menú de pausa permite cambiar entre texto pequeño, mediano y grande y ajustar la velocidad de los diálogos D0. Una ventana menor de 768×448 pausa el juego y exige pulsar **Continuar** después de ampliarla. Los diálogos D0 guardan el nodo activo y el historial antes de avanzar y se reanudan tras recargar. Las respuestas D0 y D1–D4 se guardan al elegirlas y muestran la reacción del compañero. Las conversaciones presenciales, el chat grupal y los mensajes directos usan interfaces distintas. También se recuperan el celular, el objetivo, el escritorio de la PC, la selección de clase y el nivel de pista si estaban abiertos.

## Entrega P8

El [procedimiento de construcción, staging y operación](docs/calidad/P8_OPERATIONS.md) incluye un paquete con manifiesto SHA-256, workflow de CI preparado, guardia que bloquea contenido provisional, manuales y [procedimiento de recuperación](docs/guias/RECOVERY.md). El paquete local de vista previa puede generarse con `python scripts/release.py package --channel preview --output build/mi-paquete-preview` después de exportar Web; el destino debe ser una carpeta nueva. El código está en [GitHub](https://github.com/SmashALV/Centinela). El workflow aún no se ha ejecutado en GitHub; staging y producción no están desplegados.

## Estado actual

Las [mejoras v0.41 del juego serio](docs/implementacion/MEJORAS_JUEGO_SERIO_2026-10-30.md) añaden el inventario de la mochila, una flecha de objetivo más visible, escenas más pausadas, el tutor con consejos en cada decisión, la clasificación del comportamiento, el peso del recreo en el desenlace, amigos animados que caminan y nuevos efectos de sonido. El [guion de exposición](docs/presentacion/GUION_EXPOSICION_JUGABILIDAD_2026-10-30.md) explica la jugabilidad.

La [rutina completa v0.40](docs/implementacion/DAILY_ROUTINE_2026-10-29.md) conecta D0–D4 desde el despertar hasta dormir, añade sala, calle, clase y atardecer, cambia mapas por sus bordes y ubica las PC en dormitorio y cómputo. El escritorio tiene fondo personal y accesos a Discord y Arena 5v5. El combate termina con 5 bajas o al minuto. Se integran nuevas posturas, rostros de Mateo y Sebas, variantes emocionales y avatares coherentes.

La [revisión de diálogos y chat v0.39](docs/implementacion/DIALOGUE_CHAT_2026-10-29.md) incorpora avance con clic, pausa que conserva los segundos de lectura, avatares cuadrados con mensajes largos y un fondo interior para la sala de cómputo. Ese bloque continúa integrado en la versión actual.

El [rostro actual de Camila v3](docs/arte/CAMILA_V3_ASSETS_2026-10-29.md) está integrado en ilustración, avatar y mapa.

La [aplicación del feedback de la profesora](docs/implementacion/TEACHER_FEEDBACK_IMPLEMENTATION_2026-10-29.md) añade guías D0 antes del movimiento, transición colegio–casa, devolución educativa en todos los finales, tutoría contextual, código interno oculto, despedidas animadas y una nueva identidad visual para Camila.

La [jornada compartida v0.36](docs/historia/SHARED_DAY_STORY_2026-10-29.md) permite hablar con Mateo, Camila, Sebas y Bruno durante cada día, en cualquier orden. Las decisiones cambian las conversaciones de cada compañero sin excluir a los demás. La salida cierra cada jornada después de las cuatro charlas; D1 requiere también el lobby. Los finales siguen dependiendo del apoyo o del límite digital realizado. Las partidas coral v0.1 se actualizan conservando decisiones y acciones, y reabren D2 para completar las conversaciones que antes quedaban fuera de su ruta.

La [historia candidata D1–D4](docs/historia/PLAYABLE_DRAFT.md) conecta los fragmentos recuperados, incorpora las escenas nuevas D1-03 y D2-04 y aplica condiciones reconstruidas para F01/F02/F03. El [guion integral actualizado](docs/historia/GUION_EDITORIAL_CANDIDATO_v2.md) y la [rúbrica candidata](docs/historia/rubric_candidate_v2.json) están preparados para revisión. El narrador presenta la dinámica de cada día antes de explorar un mapa con [fondo y tiles generados](docs/arte/WORLD_ASSET_PROMPTS.md) y obstáculos físicos separados; el celular y las pistas funcionan durante la exploración. El texto nuevo, los IDs y los puntajes propuestos requieren aprobación antes de publicar o generar eventos educativos.

- Recorrido técnico de Día 0 hasta el resultado del MOBA, tres ranuras locales y tests de narrativa y mecánicas básicas. Despertar, patio y chat grupal usan texto literal del [guion recuperado v0.2](docs/historia/recovered/Guion_Literal_Recuperado_Ampliado_D0_D4_v0_2.md) en una **vista previa provisional**. La opción elegida se conserva en el guardado y el chat puede releerse en el celular.
- P5 enlaza seis fragmentos recuperados con D1-03 y D2-04 redactadas y alcanza los tres desenlaces mediante dos banderas narrativas. Se guardan presentación diaria, escena, línea y opción para reanudar la lectura. La rúbrica candidata define 6 `decision_id` y 18 `choice_id` con dimensiones y 0/1/2 propuestos, fuera del cliente. Las [lagunas de la fuente y requisitos de aprobación](docs/historia/P5_SOURCE_GAPS.md) siguen documentados; el juego no muestra ni emite puntuación educativa antes de la validación.
- Los personajes y objetos usan sprites provisionales generados; las hojas de cuatro vistas, héroes, estructuras, efectos, ilustración de menú e iconos de las interfaces se describen en [`docs/arte/SPRITE_ASSETS_2026-10-28.md`](docs/arte/SPRITE_ASSETS_2026-10-28.md). Los requisitos de sustitución están en [`docs/arte/ASSETS.md`](docs/arte/ASSETS.md).
- Los tres mapas del Día 0 tienen ahora [fondos, props y tiles propios](docs/arte/DAY0_MAP_ASSETS_2026-10-28.md), con colisiones físicas separadas para muebles y obstáculos. La auditoría en ese documento también confirma los recursos D1–D4 y señala qué mobiliario sigue pintado dentro de sus fondos.
- Las conversaciones presenciales usan fondos a nivel de personaje, sprites grandes y caja inferior de novela visual. D0 en PC y el lobby de D1 usan un panel de canal con mensajes y avatares. D1-03 y D2-03 usan mensajes directos entre Sofi y Mateo; el chat de Kairo en D2 aparece en una captura diferenciada que Mateo comparte. Kairo conserva su avatar humano anónimo sin rostro. Los nuevos recursos están en `assets/vn/` y sus requisitos de reemplazo en [`docs/implementacion/VN_PRESENTATION_2026-10-28.md`](docs/implementacion/VN_PRESENTATION_2026-10-28.md).
- La música y cuatro efectos provisionales se generan de forma reproducible con `python scripts/generate_audio.py`; en Pausa se ajustan por separado y se guardan por ranura, también durante el MOBA. Los archivos y requisitos de reemplazo están en [`docs/arte/ASSETS.md`](docs/arte/ASSETS.md).
- El archivo recuperado **no es el guion original exhaustivo**: los conectores, D2-04, reacciones y cierres se redactaron como propuesta y la tabla de finales procede de una recuperación secundaria. El [mapa de IDs previo](docs/historia/recovered/Mapa_IDs_Narrativos_Propuesto_v0_1.json) sigue siendo histórico; la versión candidata define IDs nuevos, aún sin aprobación académica. Todos los JSON narrativos recuperados y candidatos conservan `ready_for_publication: false`; `data/narrative/day_0_TEST_ONLY.json` se usa solo en pruebas.
- El guardado Web usa IndexedDB con transacciones, bloqueo entre pestañas e idempotencia de solicitudes. El servicio tiene la operación atómica de snapshot más evento de decisión, pero las decisiones educativas aún no se conectan a ella porque sus IDs y ramas son provisionales. La integración Supabase está implementada y probada con servicio simulado y PostgreSQL embebido; falta comprobarla contra un proyecto real de desarrollo. No utilizar este prototipo para sesiones de investigación ni tratar sus guardados como datos definitivos.
- El [MOBA de un minuto](docs/implementacion/P2_MOBA_60S_2026-10-28.md) incluye un obstáculo central con rutas laterales, proyectiles y visión bloqueados por sólidos, ruinas de 2×2, Q de IA y escudos con expiraciones independientes. La IA rodea el muro desde ambos lados, persigue objetivos móviles y llega a su zona segura al retirarse. Las clases tienen sprites y distintivos propios; los estados activos se señalan mediante efectos y anillos. La suite simula los 60 s completos y comprueba victoria, derrota y desempates. El equilibrio con jugadores reales queda para el piloto de P7.
- El MOBA usa un [mapa de suelo propio](docs/arte/MOBA_MAP_ASSET_2026-10-28.md) con carril central, desvíos y zonas de aparición. Muro, torres, bases, ruinas y colisiones se mantienen en capas y lógica separadas del fondo.

La [auditoría del ZIP recibido el 28-10-2026](docs/historia/P5_ZIP_AUDIT_2026-10-28.md) delimita qué información nueva puede verificarse.

## Reemplazo de contenido

Con el guion original completo y validado se pueden crear `data/narrative/day_0.json` a `day_4.json` y `endings.json`, completar las ramas y conectar la progresión. Cada opción debe conservar su texto literal, destino e identificador de decisión verificados. Los assets visuales se pueden entregar por separado siguiendo `docs/arte/ASSETS.md`.
