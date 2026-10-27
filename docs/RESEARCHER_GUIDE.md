# Guía breve para el equipo investigador

El dashboard es una interfaz administrativa separada del juego. Su acceso exige una cuenta **no anónima** autorizada por UUID en el backend. La configuración actual está desactivada y las pruebas usan datos sintéticos; no hay informes reales.

1. Abrir el dashboard HTTPS de staging/producción aprobado e iniciar sesión con la cuenta administrativa asignada. No compartir contraseña ni exportar JWT.
2. Crear la sesión `SES` y registrar las versiones exactas del juego, narrativa y rúbrica antes de iniciar. Mantenerlas congeladas durante esa sesión.
3. Asociar manualmente cada código `CTN` a la sesión y clasificarlo como `validated`, `test` o `unvalidated`. Solo los validados entran en informes. El código no revela identidad y no sirve como credencial de recuperación.
4. Revisar cobertura D1–D4, sincronización, rechazos y eventos tardíos antes de cerrar. El cierre crea una versión de informe inmutable. Para incorporar eventos tardíos, crear una versión nueva con justificación explícita; la anterior permanece igual.
5. Exportar CSV/XLSX solo a un almacenamiento institucional autorizado. Comprobar la versión del informe y sus filtros; no interpretar la rúbrica `TEST_ONLY_P4_v1` como resultado académico.

Ante una interrupción o duda de integridad, seguir [RECOVERY.md](RECOVERY.md). La revisión metodológica y ética institucional es independiente de las pruebas técnicas del repositorio.
