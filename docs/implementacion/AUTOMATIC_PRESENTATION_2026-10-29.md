# Presentación automática · v0.37

La introducción muestra el texto completo y las caras de Sofi, Camila, Bruno, Mateo y Sebas. Se retiraron el título, la etiqueta de narrador, la paginación y el botón de continuación. Los guardados que estaban en una página del prólogo anterior reabren la introducción completa.

Las conversaciones presenciales, los mensajes y los interludios muestran el parlamento completo y avanzan con un tiempo de lectura calculado por longitud. La preferencia de velocidad ajusta ese tiempo. Las decisiones esperan una elección y no tienen temporizador. P pausa y Enter permite adelantar. Una escritura fallida conserva la vista y reintenta el mismo avance; cada transición sigue guardándose antes de mostrar la siguiente.

La interfaz usa una paleta lila y rosada con texto oscuro en los paneles claros. Sofi permanece a la izquierda en la novela visual y su interlocutor a la derecha. La etiqueta de nombre se coloca junto a quien habla; los mensajes remotos tienen una etiqueta centrada. Las narraciones no llevan nombre visible.

El cuarto conserva sus recorridos y añade una alfombra, guirnalda, recuerdos, libros y plantas. Se reutilizan las texturas existentes y dibujo nativo de Godot; no hay nuevos archivos gráficos que reemplazar.

Verificación: `AutoPresentationTests.tscn` prueba avance automático, texto completo, pausa, decisiones y posición de nombres. La suite general, los recorridos compartidos y los recorridos heredados pasaron. `npm run test:coral-browser` comprueba el avance real sin pulsar entre resultado e interludio y captura introducción, cuarto y novela visual en Chrome. Capturas locales: `build/web/prologue_full_pastel.png`, `build/web/bedroom_decorated.png`, `build/web/coral_day4_vn.png`.
