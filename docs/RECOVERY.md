# Recuperación y reversión de Centinela

## Si falla la sincronización de una partida

1. Mantener la pestaña y la misma ranura abiertas. En **Pausa**, consultar el estado de sincronización y usar **Reintentar sincronización** cuando vuelva la red. El guardado local de Web permanece en IndexedDB del mismo origen; no limpiar datos del navegador ni cambiar de dominio.
2. Registrar el código CTN visible, hora, versión del juego y mensaje de error, sin copiar la credencial secreta de recuperación ni datos personales al ticket.
3. Si el servidor rechaza un evento de forma permanente, conservar la partida y revisar recibos/auditoría desde el dashboard administrativo. No editar manualmente secuencias o puntuaciones.

## Si falla un despliegue Web

1. Detener nuevas sesiones en el host afectado y conservar las sesiones activas para revisión. No restaurar la base de datos como primera medida.
2. Verificar el manifiesto del artefacto instalado: `python scripts/release.py verify <carpeta-del-paquete>`.
3. Comparar el paquete actual con el candidato anterior: `python scripts/release.py rollback-check --current <actual> --previous <anterior>`. El comando bloquea cambios de esquema de guardado, código de persistencia, narrativa, rúbrica, migraciones y contenido narrativo. Un resultado positivo solo habilita un **ensayo** de reversión del cliente en staging.
4. En staging, abrir una partida guardada con el build actual usando el build anterior. Probar recarga, una decisión y sincronización sin duplicados. Registrar resultado y hashes de ambos paquetes.
5. Tras aprobación operativa, volver a publicar **solo los archivos estáticos** del paquete anterior. Conservar migraciones y registros; no ejecutar migraciones SQL inversas ni reescribir informes. Repetir el ensayo en el entorno afectado y registrar la hora.

Si las versiones difieren, desarrollar una migración de guardados y un plan de recuperación específico. La reversión de archivos estáticos no puede deshacer datos ya escritos por un servidor incompatible.

## Si la base de datos se daña

Congelar ingesta y accesos administrativos, conservar logs y recibos, evaluar alcance con el responsable de datos y revisar las copias **realmente disponibles** en el panel del proyecto. Ensayar cualquier restauración en un proyecto aislado. La restauración de Supabase puede producir indisponibilidad y pérdida de eventos posteriores al punto recuperado; comparar secuencias y acuses antes de reabrir. No asumir PITR ni retención sin comprobar el plan contratado. Ver [copias de seguridad de Supabase](https://supabase.com/docs/guides/platform/backups).
