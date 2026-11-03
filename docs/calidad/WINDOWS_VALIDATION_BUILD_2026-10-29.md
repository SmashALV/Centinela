# Ejecutable Windows de validación · 0.38.1-preview

Destino: `E:/GODOT/grooming-2/build/windows/Centinela_0.38.1_Validacion_2026-10-29/`.

El preset `Windows Validation` exporta Windows x86_64 con Godot 4.7.2 y sus plantillas de la misma versión. `binary_format/embed_pck=true` incluye los recursos en `Centinela_Validacion.exe`: no requiere Godot, navegador ni un archivo PCK externo. Se excluyen tests, documentación, dashboard, backend y dependencias de desarrollo. Es una entrega local para probar jugabilidad; no se ha desplegado en un servicio externo.

## Comprobaciones realizadas

- `RunTests.tscn`: suite general, cero fallos.
- `CoralRoutesTests.tscn`: jornadas compartidas en tres órdenes, F01/F02/F03 y reanudación.
- `TeacherFeedbackTests.tscn`: guías D0, continuidad, código oculto, tutoría, despedidas y devoluciones finales.
- `AutoPresentationTests.tscn`: lectura automática, pausa, nombres y decisiones sin temporizador.
- `MobaReturnTests.tscn`: MOBA → reacción de Camila → interludio → Día 1 con los cuatro compañeros. La comprobación se actualizó al contrato actual de avance automático.
- `StoryRoutesTests.tscn`: cinco recorridos de compatibilidad para guardados anteriores.
- `python scripts/release.py check --channel preview`: aprobado para validación local.
- `python tests/verify_recovered_script.py`: fragmentos recuperados intactos.
- Ejecutable exportado: arranque independiente en modo headless, salida 0 y sin errores de carga o script.

Los registros se conservan en `build/validation/windows-0.38.1/`. Estas pruebas automáticas y el arranque no sustituyen una partida manual completa en el equipo del evaluador.

## Archivos entregados

`Centinela_Validacion.exe`, `LEEME_VALIDACION.txt`, `PRUEBAS.txt` y `manifest.json`. El manifiesto incluye revisión Git, versión y hashes SHA-256 de los archivos. El ZIP hermano contiene esos mismos archivos para trasladarlos juntos.

Las partidas de escritorio están en `%APPDATA%/Godot/app_userdata/Centinela 2.0/`; son independientes de las partidas Web del navegador. La exportación puede abrir partidas locales anteriores. Para revisar el recorrido completo se recomienda una ranura nueva o rehacer una ranura desde el menú.

## Alcance de la validación

Están implementadas las correcciones jugables de las revisiones recientes. Sigue pendiente la revisión docente del cierre educativo y cualquier decisión académica sobre el protocolo de aplicación. El backend remoto y el dashboard no forman parte de esta validación de Windows; el juego guarda localmente y no calcula puntuación educativa.

Para registrar un problema conviene anotar la jornada, el personaje, la opción elegida y si ocurrió al pausar o reanudar, junto con una captura de pantalla.

## Exportación tras la migración modular · 03-11-2026

- **Ejecutable:** `build/windows/Centinela_Modular_2026-11-03/Centinela_Rutina.exe` (219 MB, paquete incluido). SHA-256 `2b25fb2e032ff4d7bf2dec5bd3e66cf2e4c09ec3e7d48fb18ea0af26223ce58d`.
- **Contenido:** el preset Windows Validation incluye ahora `data/routine/*.json` y `data/maps/*.json`, además del guion narrativo.
- **Comprobación del paquete:** se exportó el mismo contenido como `.pck` y se abrió con Godot 4.7.2 (`--main-pack`). Los tres JSON están dentro. `RoutineCatalog` valida las 7 escenas de la rutina; `MapCatalog` valida los 14 mapas y carga sus 14 fondos; la regla del final responde igual que en el proyecto.
- **Arranque:** el ejecutable se abrió en ventana y se cerró solo tras unos segundos (`--quit-after`), con código de salida 0 y sin errores en su registro. No se jugó un recorrido completo con el ejecutable.
- **Limpieza (03-11-2026):** se borraron de `build/` los ejecutables anteriores (0.38.1, 0.39.0, 0.40.0 Rutina y Arte, con sus ZIP), los paquetes `release-*` de las versiones 0.32–0.34, los registros de `build/validation/` y las capturas de las pruebas de navegador. Solo quedan este ejecutable y la exportación Web en `build/web/`. Las capturas se vuelven a generar con `npm run test:browser`.
