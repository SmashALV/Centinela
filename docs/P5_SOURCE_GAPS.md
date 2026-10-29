# P5 · Vista previa de D1–D4 y finales

**Actualización:** existe una [historia jugable candidata v0.2](PLAYABLE_DRAFT.md) y un [guion integral para revisión](GUION_EDITORIAL_CANDIDATO_v1.md). La nueva D2-04 y los parlamentos de enlace se identifican como texto redactado. Los huecos de la fuente original enumerados aquí no se convierten por ello en texto histórico aprobado.

Esta fase incorpora únicamente los parlamentos literales recuperados del documento `Guion_Literal_Recuperado_Ampliado_D0_D4_v0_2.md`. La fuente está en `docs/recovered/` y los archivos de ejecución están en `data/narrative/`. Todos llevan `provisional: true` y `ready_for_publication: false`.

Al terminar el MOBA del Día 0, el botón **Ver fragmentos D1–D4** abre seis escenas recuperadas. Cada línea y opción se puede recorrer; la escena, posición y letra elegida se guardan en la ranura. Las escenas D1, D2 y D3 se presentan como fragmentos sucesivos porque faltan los conectores entre días. La fuente sí confirma que D4-01, D4-02 y D4-03 forman una conversación continua, aunque no aporta todas las reacciones a las opciones.

Las líneas de despedida de D1 y las variantes de Mateo de D3 se muestran aparte como **líneas sin posición confirmada**. La continuación de D2 se muestra con una nota porque no consta su enlace con cada opción. El chat posterior de F03 se separa porque no se conoce su intercalado. Los cuatro extractos de finales se abren desde un índice manual: la fuente no permite asignar uno automáticamente.

Las opciones de esta vista previa no generan puntuación educativa, eventos de decisión ni un estado de historia completada. Tampoco se envían a Supabase. El mapa de IDs adjunto es una propuesta y no se usa como identificador canónico ni como base de migración.

## Para sustituir la vista previa por la historia definitiva

Se necesita el guion aprobado completo con:

1. La reacción de Camila al resultado del MOBA y los conectores D0→D1, D1→D2 y D2→D3.
2. Los destinos y parlamentos posteriores de cada opción A/B/C, incluidas las posiciones de las líneas recuperadas sin ubicar y la continuidad de D3→D4.
3. La ubicación y orden exactos de los mensajes del chat posterior de F03.
4. Los IDs canónicos de escenas y decisiones, sus reglas de puntuación educativa y las fórmulas verificadas para los finales.
5. La aprobación editorial del texto y de las rutas para publicación.

Al recibirlo, generar archivos canónicos nuevos en lugar de cambiar el significado de `*_RECOVERED_PREVIEW.json`. Cualquier cambio que afecte guardados existentes debe definir una migración explícita.

No se añadieron assets visuales nuevos en P5. Los personajes y escenarios siguen siendo dibujos provisionales; `docs/ASSETS.md` indica cómo reemplazarlos.
