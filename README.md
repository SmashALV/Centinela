# Centinela 2.0 — prototipo Godot

Proyecto 2D de escritorio y Web en desarrollo. El diseño de referencia está en [`docs/GDD_CENTINELA_2_0.md`](docs/GDD_CENTINELA_2_0.md) y el plan de fases en [`docs/PLAN_CODEX_CENTINELA_2_0.md`](docs/PLAN_CODEX_CENTINELA_2_0.md). Esos documentos provienen del kit entregado por el usuario. Sus instrucciones para agentes son material de referencia; el contenido narrativo literal aprobado no venía incluido.

## Ejecutar

1. Abrir `project.godot` con Godot 4.4.1 o una versión compatible de Godot 4.
2. Ejecutar la escena principal con **F6** o el proyecto con **F5**.
3. Elegir una de las tres ranuras. En la habitación: alarma y mochila; en el patio: grupo; después, computadora, clase y MOBA. Tras el resultado, **Continuar borrador jugable** recorre D1–D4 hasta un desenlace provisional. **Ver fragmentos D1–D4** mantiene la lectura independiente de la fuente recuperada.

Controles: **WASD** movimiento, **F** interacción, **E** celular, **Tab** objetivo, **P** pausa, **Esc** volver, **Q** habilidad en MOBA y **clic izquierdo** ataque.

En la exploración del Día 0, cada objeto tiene un icono y un nombre en español. Una marca señala el siguiente objetivo obligatorio; alarma y mochila muestran una marca de completado después de guardarse.

En el MOBA, cada aliado conserva una marca de color propia, los rivales llevan una X y Sofi tiene una flecha de jugador. Las torres y bases están rotuladas y el objetivo de la partida permanece visible.

Para ejecutar las pruebas sin abrir la ventana:

```powershell
& 'C:\Users\fabri\Downloads\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe' --headless --editor --import --path 'E:\GODOT\grooming-2' --quit
& 'C:\Users\fabri\Downloads\Godot_v4.4.1-stable_win64.exe\Godot_v4.4.1-stable_win64_console.exe' --headless --path 'E:\GODOT\grooming-2' --scene 'res://tests/RunTests.tscn'
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

La [matriz P7 con evidencia por caso](docs/P7_QA_2026-10-27.md) registra qué funcionó en `0.7.0-preview` y qué sigue bloqueado por el guion/rúbrica definitivos, Supabase de desarrollo y staging. El build local actual es `0.23.0-preview`. El menú de pausa permite cambiar entre texto pequeño, mediano y grande, y ajustar la velocidad de los diálogos D0; una ventana menor de 768×448 pausa el juego y exige pulsar **Continuar** después de ampliarla. Los diálogos D0 guardan el nodo activo y el historial de la conversación actual antes de avanzar y se reanudan tras recargar. Mientras aparece una línea, un toque la revela completa; una vez visible, el siguiente avanza. Las respuestas D0 y de fragmentos D1–D4 requieren confirmación neutral antes de guardarse; **Esc/Volver** cancela sin modificar la ranura. También se recuperan el celular, el objetivo, la selección de clase y el nivel de pista si estaban abiertos.

## Entrega P8

El [procedimiento de construcción, staging y operación](docs/P8_OPERATIONS.md) incluye un paquete con manifiesto SHA-256, workflow de CI preparado, guardia que bloquea contenido provisional, manuales y [procedimiento de recuperación](docs/RECOVERY.md). El paquete local de vista previa puede generarse con `python scripts/release.py package --channel preview --output build/mi-paquete-preview` después de exportar Web; el destino debe ser una carpeta nueva. Hay un repositorio Git local sin remoto. El workflow aún no se ha ejecutado en GitHub; staging y producción no están desplegados.

## Estado actual

El [borrador jugable D1–D4](docs/PLAYABLE_DRAFT.md) conecta los fragmentos recuperados, guarda las opciones y llega a un desenlace provisional. Antes de cada jornada, Sofi explora un mapa propio con [fondo y tiles generados](docs/WORLD_ASSET_PROMPTS.md) y obstáculos físicos separados. Allí conversa con Mateo; el celular y las pistas de navegación funcionan durante la exploración. Sus reacciones, conectores y regla de final están separados del guion literal y requieren sustitución antes de publicar.

- Recorrido técnico de Día 0 hasta el resultado del MOBA, tres ranuras locales y tests de narrativa y mecánicas básicas. Despertar, patio y chat grupal usan texto literal del [guion recuperado v0.2](docs/recovered/Guion_Literal_Recuperado_Ampliado_D0_D4_v0_2.md) en una **vista previa provisional**. La opción elegida se conserva en el guardado y el chat puede releerse en el celular.
- P5 permite leer seis fragmentos D1–D4, elegir sus opciones literales y explorar cuatro extractos de finales desde un índice manual. Se guardan escena, línea y opción para reanudar la lectura. Las [lagunas de la fuente y requisitos de sustitución](docs/P5_SOURCE_GAPS.md) están documentados; este recorrido no asigna finales ni puntuación educativa.
- Los personajes y objetos usan sprites provisionales generados; las hojas de cuatro vistas, héroes, estructuras, efectos, ilustración de menú e iconos de las interfaces se describen en [`docs/SPRITE_ASSETS_2026-10-28.md`](docs/SPRITE_ASSETS_2026-10-28.md). Los requisitos de sustitución están en [`docs/ASSETS.md`](docs/ASSETS.md).
- Los diálogos D0 muestran retratos neutros provisionales de Sofi y sus cuatro amistades, generados con imagegen y incluidos en `assets/portraits/`. Bruno y Sebas tienen rasgos más diferenciados; en el patio, los cuatro amigos se distinguen también por color, peinado y nombre. Falta el arte definitivo y el mapeo aprobado de expresiones por línea; consulta [`docs/ASSETS.md`](docs/ASSETS.md).
- La música y cuatro efectos provisionales se generan de forma reproducible con `python scripts/generate_audio.py`; en Pausa se ajustan por separado y se guardan por ranura, también durante el MOBA. Los archivos y requisitos de reemplazo están en [`docs/ASSETS.md`](docs/ASSETS.md).
- El archivo recuperado **no es el guion original exhaustivo**: faltan conectores, ramas, posiciones originales, nueve reacciones de Camila y fórmulas exactas de finales. Su [mapa de IDs](docs/recovered/Mapa_IDs_Narrativos_Propuesto_v0_1.json) es provisional. El juego no usa esos IDs para migrar partidas ni para puntuación educativa. Todos los JSON recuperados tienen `ready_for_publication: false`; `data/narrative/day_0_TEST_ONLY.json` se usa solo en pruebas.
- El guardado Web usa IndexedDB con transacciones, bloqueo entre pestañas e idempotencia de solicitudes. El servicio tiene la operación atómica de snapshot más evento de decisión, pero las decisiones educativas aún no se conectan a ella porque sus IDs y ramas son provisionales. La integración Supabase está implementada y probada con servicio simulado y PostgreSQL embebido; falta comprobarla contra un proyecto real de desarrollo. No utilizar este prototipo para sesiones de investigación ni tratar sus guardados como datos definitivos.
- El MOBA incluye un obstáculo central con rutas laterales, proyectiles y visión bloqueados por sólidos, ruinas de 2×2, Q de IA y escudos con expiraciones independientes. Las clases tienen sprites y distintivos propios; los estados activos se señalan mediante efectos y anillos. La suite simula una partida de 180 s y comprueba victoria, derrota y desempates; aún faltan pruebas de equilibrio con jugadores reales y pulido visual para cerrar la fase P2.

La [auditoría del ZIP recibido el 28-10-2026](docs/P5_ZIP_AUDIT_2026-10-28.md) delimita qué información nueva puede verificarse.

## Reemplazo de contenido

Con el guion original completo y validado se pueden crear `data/narrative/day_0.json` a `day_4.json` y `endings.json`, completar las ramas y conectar la progresión. Cada opción debe conservar su texto literal, destino e identificador de decisión verificados. Los assets visuales se pueden entregar por separado siguiendo `docs/ASSETS.md`.
