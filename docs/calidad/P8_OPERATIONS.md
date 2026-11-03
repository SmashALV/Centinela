# P8 · Entrega, staging y operación

**Estado:** paquete y verificaciones locales preparados; staging y producción sin desplegar. Se inicializó Git local, pero aún no hay remoto ni ejecución de GitHub Actions. No hay servidor Web de staging ni acceso de la CLI al proyecto Supabase. El guion y la rúbrica aprobados tampoco están disponibles. `0.7.0-preview` es solo un prototipo técnico.

## Construcción reproducible

La fuente de verdad es el código, `package-lock.json` y `export_presets.cfg`. El workflow `.github/workflows/quality.yml` está listo para ejecutarse cuando se conecte el repositorio a GitHub: instala dependencias con `npm ci`, comprueba el texto recuperado, corre pruebas SQL/locales, valida las Edge Functions, ejecuta Godot 4.7.2, exporta Web, prueba Chrome y publica **un artefacto de CI**, no un sitio. Todavía no se ha ejecutado en GitHub.

Para repetir el empaquetado de vista previa en este equipo, después de `npm ci`:

```powershell
python tests/verify_recovered_script.py
python -m unittest discover -s tests -p test_release.py -v
npm run test:web-storage
npm run test:web-sync
npm run test:backend-sql
npm run test:research-sql
npm run test:dashboard-export
npm run test:dashboard-browser
godot --headless --path . --scene res://tests/RunTests.tscn
godot --headless --path . --scene res://tests/MobaReturnTests.tscn
godot --headless --path . --scene res://tests/StoryRoutesTests.tscn
godot --headless --path . --export-debug 'Web Development' build/web/index.html
npm run test:browser
python scripts/release.py package --channel preview --output build/release-preview
python scripts/release.py verify build/release-preview
```

El destino del paquete debe ser una carpeta nueva dentro de `build/`. Incluye `game/`, `dashboard/` y `manifest.json`. Solo copia archivos `index.*` de la exportación Web: las capturas de QA no se distribuyen. El empaquetador rechaza una exportación anterior al código fuente. El manifiesto contiene SHA-256 y tamaño de cada archivo distribuido, además de hashes de fuentes narrativas, migraciones, funciones y código del juego; identifica versión del juego, esquema de guardado, narrativa, rúbrica y commit si hay Git. No contiene credenciales privadas. El hash prueba integridad del paquete; no demuestra por sí solo equivalencia binaria entre sistemas operativos.

La guardia de cualquier canal, incluida vista previa, examina fuentes del cliente y detiene el paquete si encuentra una clave privada `sb_secret_`, una asignación de clave `service_role`/HMAC o un JWT con rol `service_role`. La prueba de regresión usa exclusivamente valores sintéticos.

**Evidencia local del 27-10-2026:** `tests/test_release.py` pasó 4/4 casos (bloqueo de promoción, detección de alteración, exportación caducada y comparación de rollback); Godot 4.7.2 exportó Web; `npm run test:browser` pasó en Chrome sin errores; el paquete `build/release-p8-20261027/` se generó y verificó. La suite Godot, Edge y pruebas de backend/dashboard de P7 constan en [P7_QA_2026-10-27.md](P7_QA_2026-10-27.md). El workflow de GitHub aún no se ha ejecutado.

**Estado remoto comprobado el 27-10-2026:** Supabase Auth expone `anonymous_users: false`; las cinco rutas de Edge Functions devuelven HTTP 404; `npx supabase projects list` exige iniciar sesión y Docker Desktop no responde. No se aplicaron migraciones ni se enviaron datos de prueba.

## Puerta de staging

`python scripts/release.py check --channel staging` bloquea el prototipo actual. Para abrir esa puerta hacen falta guion completo y aprobado en `data/narrative/day_0.json`…`day_4.json` y `endings.json`, rutas jugables conectadas a esos archivos, rúbrica aprobada y versionada, versión del juego sin `preview`, y configuraciones HTTPS activas y concordantes para juego y dashboard. El preset `Web Staging` excluye los JSON provisionales y de test. No debe ejecutarse con esos archivos todavía ausentes.

Cuando estén disponibles, crear un proyecto Supabase **staging** independiente; aplicar migraciones revisadas sin `seed.sql`; configurar Auth anónima para el juego, cuenta administrativa no anónima permitida por UUID, origenes CORS exactos, `RECOVERY_HMAC_KEY` y demás secretos **solo en el servidor**. Configurar `web/backend_config.json` y `dashboard/config.json` con la URL y la clave publicable de staging; no reutilizar el proyecto de desarrollo entregado como staging. Ejecutar `godot --export-release 'Web Staging' build/web/index.html`, pruebas locales y `python scripts/release.py package --channel staging --output build/release-staging`. Publicar `game/` y `dashboard/` en orígenes HTTPS separados del host de staging elegido. El mecanismo automático de publicación se añadirá cuando exista un host/destino aprobado; el workflow actual no realiza despliegues.

Probar una partida sintética desde cero y registrar: manifest, versión de migraciones, salida de pruebas, captura del juego, evento de decisión canónico en IndexedDB y Supabase, acuse, clasificación como `test`, dashboard e informe de prueba. La prueba E2E actual (`npm run test:backend-e2e`) se limita deliberadamente a `CENTINELA_TEST_ENV=development`; debe ampliarse para staging con fixtures aprobados antes de usarla allí. Nunca usar estudiantes en esta prueba.

## Congelación y promoción

Registrar en cada sesión la versión del juego, narrativa y rúbrica. El servidor bloquea la rúbrica por partida; una sesión de investigación iniciada no debe cambiar de versión narrativa o rúbrica. Promover a producción solo el artefacto exacto validado en staging, con su manifiesto, tras aprobación humana explícita e independiente de la revisión metodológica/ética aplicable. El script rechaza `--channel production` por diseño; no hay flujo automático de producción.

## Secretos y copias de seguridad

- En el paquete Web solo pueden figurar la URL y la clave **publicable**. No incluir `service_role`, contraseña administrativa, JWT, clave HMAC, `.env.local`, dumps ni datos de estudiantes.
- Mantener `ALLOW_TEST_RUBRIC` desactivado fuera de desarrollo. `seed.sql` es sintético y no se aplica en staging ni producción.
- Comprobar en el **proyecto concreto** el plan contratado, el panel `Database > Backups`, retención visible, PITR si procede, alcance de Storage y una restauración ensayada a un proyecto aislado. Esta comprobación no se ha podido hacer sin acceso al proyecto/plan.
- La [documentación actual de Supabase](https://supabase.com/docs/guides/platform/backups) indica copias diarias en Pro/Team/Enterprise, PITR como complemento y recomienda exportaciones externas para Free. Una copia física o PITR no implica que los objetos de Storage estén incluidos. Verificar capacidad y política reales antes de operar con menores.

El procedimiento de reversión está en [RECOVERY.md](../guias/RECOVERY.md). Los manuales de uso están en [STUDENT_GUIDE.md](../guias/STUDENT_GUIDE.md) y [RESEARCHER_GUIDE.md](../guias/RESEARCHER_GUIDE.md).
