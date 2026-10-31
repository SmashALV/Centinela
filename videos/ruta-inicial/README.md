# Presentación · Ruta inicial (Día 0)

Video Remotion de ~2 min 56 s (1920×1080, 30 fps) que explica la jugabilidad del Día 0 de Centinela 2.0. Sigue el guion de [docs/GUION_GRABACION_RUTA_INICIAL.md](../../docs/GUION_GRABACION_RUTA_INICIAL.md): portada, 13 bloques y cierre. Cada bloque muestra capturas reales del juego, un panel lateral (controles, opciones o reglas) y un subtítulo con la narración sugerida. Tiene música suave del juego y sonidos puntuales (notificación, campana y resultado). No incluye voz: se puede grabar encima siguiendo los subtítulos.

## Uso

```powershell
npm ci
npm run dev                                                  # Remotion Studio
npx remotion render RutaInicial out/Centinela_ruta_inicial_D0.mp4
```

El texto, la duración y las capturas de cada bloque se editan en `src/data.ts`. Los colores, en `src/theme.ts`.

## Capturas

`public/capturas/*.png` se generan desde la exportación Web (`build/web`) con Chrome:

```powershell
# desde la raíz del repositorio
node videos/ruta-inicial/capture/capture_d0.cjs
```

El script juega el inicio de una ranura nueva y luego carga estados del Día 0 en IndexedDB para cada escena. En la captura actual se eligió la respuesta B en Discord y la partida terminó en derrota 3 a 5 a los 39 s; el subtítulo del bloque de la Arena lo menciona. Si se vuelve a capturar y cambia el resultado, hay que actualizar ese subtítulo.

`public/personajes` y `public/audio` son copias de `assets/vn` y `assets/audio`.
