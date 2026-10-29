# Centinela 2.0 — prototipo Godot

Proyecto 2D de escritorio y Web en desarrollo. El diseño de referencia está en [`docs/GDD_CENTINELA_2_0.md`](docs/GDD_CENTINELA_2_0.md) y el plan de fases en [`docs/PLAN_CODEX_CENTINELA_2_0.md`](docs/PLAN_CODEX_CENTINELA_2_0.md). Esos documentos provienen del kit entregado por el usuario. Sus instrucciones para agentes son material de referencia; el contenido narrativo literal aprobado no venía incluido.

## Ejecutar

1. Abrir `project.godot` con Godot 4.4.1 o una versión compatible de Godot 4.
2. Ejecutar la escena principal con **F6** o el proyecto con **F5**.
3. Elegir una de las tres ranuras. En la habitación: alarma y mochila; en el patio: grupo; después, usar la PC, abrir el chat en su escritorio ficticio, elegir clase y jugar el MOBA. En el menú, **Rehacer** inicia esa ranura desde el prólogo y **Borrar** la deja vacía; ambas acciones piden confirmación. Durante el MOBA, **P** permite salir al menú. Al terminar la partida, **Continuar** muestra la reacción de Camila; luego el narrador presenta a Sofi al día siguiente y abre el recorrido del Día 1.

Controles: **WASD** movimiento, **F** interacción, **E** celular, **Tab** objetivo, **P** pausa, **Esc** volver, **Q** habilidad en MOBA y **clic izquierdo** ataque.

Al crear una partida, el Día 0 presenta una introducción completa con las caras de Sofi y sus amigos, sin título ni etiqueta de narrador. El texto aparece completo y avanza automáticamente según su longitud. Las decisiones esperan al jugador; **P** pausa la lectura y **Enter** permite adelantarla. Las señales se descubren durante la historia. La [presentación automática y la interfaz lila y rosada](docs/AUTOMATIC_PRESENTATION_2026-10-29.md) incluyen nombres junto al personaje que habla y más decoración en el cuarto.

En el MOBA, cada aliado conserva una marca de color propia, los rivales llevan una X y Sofi tiene una flecha de jugador. Las torres y bases están rotuladas y el objetivo de la partida permanece visible.

Para ejecutar las pruebas sin abrir la ventana:

```powershell
& 'C:\Users\fabri\Downloads\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe' --headless --editor --import --path 'E:\GODOT\grooming-2' --quit
& 'C:\Users\fabri\Downloads\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe' --headless --path 'E:\GODOT\grooming-2' --scene 'res://tests/RunTests.tscn'
& 'C:\Users\fabri\Downloads\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe' --headless --path 'E:\GODOT\grooming-2' --scene 'res://tests/MobaReturnTests.tscn'
& 'C:\Users\fabri\Downloads\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe' --headless --path 'E:\GODOT\grooming-2' --scene 'res://tests/StoryRoutesTests.tscn'
& 'E:\GODOT\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe' --headless --path 'E:\GODOT\grooming-2' --scene 'res://tests/CoralRoutesTests.tscn'
```

La suite devuelve código distinto de cero cuando falla una comprobación. Se ha probado con Godot 4.4.1 y 4.7.2.

## Versión Web

El preset **Web Development** exporta con Godot 4.7.2 y sus plantillas de la misma versión. Desde la raíz del proyecto:

```powershell
godot --headless --path . --export-debug 'Web Development' build/web/index.html
python -m http.server 8000 -d build/web
```

Abrir `http://localhost:8000`. El guardado Web usa IndexedDB en el origen del sitio: las partidas de `localhost:8000` y de un dominio publicado son independientes. Hay tres ranuras, escritura transaccional, bloqueo por pestaña y recuperación al recargar. La recarga conserva el bloqueo de esa pestaña; una pestaña distinta no puede editar la misma ranura mientras esté abierta o hasta que venza el bloqueo (30 s). El modo escritorio sigue usando archivos `user://`.

En escritorio, cada guardado se escribe primero en un archivo temporal y conserva una copia local de la versión anterior. Si el archivo principal se daña o falta, la ranura se abre desde esa copia y se repara en el siguiente guardado. El [procedimiento de recuperación](docs/RECOVERY.md) describe este caso.

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

La base P4 está en [`supabase/README.md`](supabase/README.md): migración PostgreSQL, cuatro Edge Functions, cola Web, Auth anónima y pruebas sintéticas. `web/backend_config.json` contiene la URL y clave publicable del proyecto de desarrollo, pero `enabled` permanece en `false` hasta desplegar el backend y activar Auth anónima. El juego sigue guardando localmente. El resultado del MOBA se encola como evento descriptivo al activar esa configuración. No se calcula ninguna puntuación educativa en el cliente.

## Dashboard del investigador

La base P6 está en [`dashboard/index.html`](dashboard/index.html) y [`docs/P6_STATUS.md`](docs/P6_STATUS.md). Administra sesiones SES, clasificación manual de códigos CTN, cobertura D1–D4, informes versionados y exportaciones CSV/XLSX. Funciona localmente con datos sintéticos y respuestas simuladas; `dashboard/config.json` permanece desactivado hasta desplegar P4/P6 y provisionar una cuenta administrativa no anónima en desarrollo. Las partidas de prueba y no validadas no entran en informes publicados.

```powershell
npm run test:research-sql
npm run test:dashboard-export
npm run test:dashboard-browser
```

## QA técnico

La [matriz P7 con evidencia por caso](docs/P7_QA_2026-10-27.md) registra qué funcionó en `0.7.0-preview` y qué sigue bloqueado por aprobación de contenido, Supabase de desarrollo y staging. El [cierre técnico y de requisitos no funcionales](docs/NFR_CLOSEOUT_2026-10-28.md) registra pruebas de rutas y seguridad de entrega. El build local actual es `0.38.1-preview`; la [verificación P0–P1](docs/P0_P1_CLOSURE_2026-10-28.md) detalla el recorrido local. La [gestión de ranuras](docs/SLOT_MANAGEMENT_2026-10-28.md) explica el reinicio y borrado local; la [continuidad D0→D1](docs/D0_D1_CONTINUITY_2026-10-28.md) registra la transición. El menú de pausa permite cambiar entre texto pequeño, mediano y grande y ajustar la velocidad de los diálogos D0. Una ventana menor de 768×448 pausa el juego y exige pulsar **Continuar** después de ampliarla. Los diálogos D0 guardan el nodo activo y el historial antes de avanzar y se reanudan tras recargar. Las respuestas D0 y D1–D4 se guardan al elegirlas y muestran la reacción del compañero. Las conversaciones presenciales, el chat grupal y los mensajes directos usan interfaces distintas. También se recuperan el celular, el objetivo, el escritorio de la PC, la selección de clase y el nivel de pista si estaban abiertos.

## Entrega P8

El [procedimiento de construcción, staging y operación](docs/P8_OPERATIONS.md) incluye un paquete con manifiesto SHA-256, workflow de CI preparado, guardia que bloquea contenido provisional, manuales y [procedimiento de recuperación](docs/RECOVERY.md). El paquete local de vista previa puede generarse con `python scripts/release.py package --channel preview --output build/mi-paquete-preview` después de exportar Web; el destino debe ser una carpeta nueva. Hay un repositorio Git local sin remoto. El workflow aún no se ha ejecutado en GitHub; staging y producción no están desplegados.

## Estado actual

El [rostro actual de Camila v3](docs/CAMILA_V3_ASSETS_2026-10-29.md) está integrado en ilustración, avatar y mapa.

La [aplicación del feedback de la profesora](docs/TEACHER_FEEDBACK_IMPLEMENTATION_2026-10-29.md) añade guías D0 antes del movimiento, transición colegio–casa, devolución educativa en todos los finales, tutoría contextual, código interno oculto, despedidas animadas y una nueva identidad visual para Camila.

La [jornada compartida v0.36](docs/SHARED_DAY_STORY_2026-10-29.md) permite hablar con Mateo, Camila, Sebas y Bruno durante cada día, en cualquier orden. Las decisiones cambian las conversaciones de cada compañero sin excluir a los demás. La salida cierra cada jornada después de las cuatro charlas; D1 requiere también el lobby. Los finales siguen dependiendo del apoyo o del límite digital realizado. Las partidas coral v0.1 se actualizan conservando decisiones y acciones, y reabren D2 para completar las conversaciones que antes quedaban fuera de su ruta.

La [historia candidata D1–D4](docs/PLAYABLE_DRAFT.md) conecta los fragmentos recuperados, incorpora las escenas nuevas D1-03 y D2-04 y aplica condiciones reconstruidas para F01/F02/F03. El [guion integral actualizado](docs/GUION_EDITORIAL_CANDIDATO_v2.md) y la [rúbrica candidata](docs/rubric_candidate_v2.json) están preparados para revisión. El narrador presenta la dinámica de cada día antes de explorar un mapa con [fondo y tiles generados](docs/WORLD_ASSET_PROMPTS.md) y obstáculos físicos separados; el celular y las pistas funcionan durante la exploración. El texto nuevo, los IDs y los puntajes propuestos requieren aprobación antes de publicar o generar eventos educativos.

- Recorrido técnico de Día 0 hasta el resultado del MOBA, tres ranuras locales y tests de narrativa y mecánicas básicas. Despertar, patio y chat grupal usan texto literal del [guion recuperado v0.2](docs/recovered/Guion_Literal_Recuperado_Ampliado_D0_D4_v0_2.md) en una **vista previa provisional**. La opción elegida se conserva en el guardado y el chat puede releerse en el celular.
- P5 enlaza seis fragmentos recuperados con D1-03 y D2-04 redactadas y alcanza los tres desenlaces mediante dos banderas narrativas. Se guardan presentación diaria, escena, línea y opción para reanudar la lectura. La rúbrica candidata define 6 `decision_id` y 18 `choice_id` con dimensiones y 0/1/2 propuestos, fuera del cliente. Las [lagunas de la fuente y requisitos de aprobación](docs/P5_SOURCE_GAPS.md) siguen documentados; el juego no muestra ni emite puntuación educativa antes de la validación.
- Los personajes y objetos usan sprites provisionales generados; las hojas de cuatro vistas, héroes, estructuras, efectos, ilustración de menú e iconos de las interfaces se describen en [`docs/SPRITE_ASSETS_2026-10-28.md`](docs/SPRITE_ASSETS_2026-10-28.md). Los requisitos de sustitución están en [`docs/ASSETS.md`](docs/ASSETS.md).
- Los tres mapas del Día 0 tienen ahora [fondos, props y tiles propios](docs/DAY0_MAP_ASSETS_2026-10-28.md), con colisiones físicas separadas para muebles y obstáculos. La auditoría en ese documento también confirma los recursos D1–D4 y señala qué mobiliario sigue pintado dentro de sus fondos.
- Las conversaciones presenciales usan fondos a nivel de personaje, sprites grandes y caja inferior de novela visual. D0 en PC y el lobby de D1 usan un panel de canal con mensajes y avatares. D1-03 y D2-03 usan mensajes directos entre Sofi y Mateo; el chat de Kairo en D2 aparece en una captura diferenciada que Mateo comparte. Kairo conserva su avatar humano anónimo sin rostro. Los nuevos recursos están en `assets/vn/` y sus requisitos de reemplazo en [`docs/VN_PRESENTATION_2026-10-28.md`](docs/VN_PRESENTATION_2026-10-28.md).
- La música y cuatro efectos provisionales se generan de forma reproducible con `python scripts/generate_audio.py`; en Pausa se ajustan por separado y se guardan por ranura, también durante el MOBA. Los archivos y requisitos de reemplazo están en [`docs/ASSETS.md`](docs/ASSETS.md).
- El archivo recuperado **no es el guion original exhaustivo**: los conectores, D2-04, reacciones y cierres se redactaron como propuesta y la tabla de finales procede de una recuperación secundaria. El [mapa de IDs previo](docs/recovered/Mapa_IDs_Narrativos_Propuesto_v0_1.json) sigue siendo histórico; la versión candidata define IDs nuevos, aún sin aprobación académica. Todos los JSON narrativos recuperados y candidatos conservan `ready_for_publication: false`; `data/narrative/day_0_TEST_ONLY.json` se usa solo en pruebas.
- El guardado Web usa IndexedDB con transacciones, bloqueo entre pestañas e idempotencia de solicitudes. El servicio tiene la operación atómica de snapshot más evento de decisión, pero las decisiones educativas aún no se conectan a ella porque sus IDs y ramas son provisionales. La integración Supabase está implementada y probada con servicio simulado y PostgreSQL embebido; falta comprobarla contra un proyecto real de desarrollo. No utilizar este prototipo para sesiones de investigación ni tratar sus guardados como datos definitivos.
- El [MOBA de un minuto](docs/P2_MOBA_60S_2026-10-28.md) incluye un obstáculo central con rutas laterales, proyectiles y visión bloqueados por sólidos, ruinas de 2×2, Q de IA y escudos con expiraciones independientes. La IA rodea el muro desde ambos lados, persigue objetivos móviles y llega a su zona segura al retirarse. Las clases tienen sprites y distintivos propios; los estados activos se señalan mediante efectos y anillos. La suite simula los 60 s completos y comprueba victoria, derrota y desempates. El equilibrio con jugadores reales queda para el piloto de P7.
- El MOBA usa un [mapa de suelo propio](docs/MOBA_MAP_ASSET_2026-10-28.md) con carril central, desvíos y zonas de aparición. Muro, torres, bases, ruinas y colisiones se mantienen en capas y lógica separadas del fondo.

La [auditoría del ZIP recibido el 28-10-2026](docs/P5_ZIP_AUDIT_2026-10-28.md) delimita qué información nueva puede verificarse.

## Reemplazo de contenido

Con el guion original completo y validado se pueden crear `data/narrative/day_0.json` a `day_4.json` y `endings.json`, completar las ramas y conectar la progresión. Cada opción debe conservar su texto literal, destino e identificador de decisión verificados. Los assets visuales se pueden entregar por separado siguiendo `docs/ASSETS.md`.
