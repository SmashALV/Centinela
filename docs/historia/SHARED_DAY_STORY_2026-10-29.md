# Jornadas compartidas · v0.36

La revisión solicitada elimina la selección exclusiva de compañeros. Mateo, Camila, Sebas y Bruno están disponibles durante D1–D4. El jugador escoge el orden de las cuatro conversaciones; terminar una charla devuelve a la exploración. La salida permite cerrar la jornada después de hablar con todos. En D1 también se prepara la partida en el lobby, seguida del privado con Mateo.

Las respuestas a Camila, Mateo y Sebas en D2 se guardan por separado. En D3 y D4, cada uno recuerda su propia conversación. Bruno participa cada día y su diálogo cambia con lo ocurrido en el grupo. Ninguna respuesta bloquea a otro compañero. Repetir una interacción ya completada informa de su estado y evita duplicar decisiones.

El prólogo solo presenta a Sofi, su rutina, sus amigos y la forma de jugar. Las preguntas de las ayudas y las explicaciones del narrador aparecen conforme Sofi observa hechos o escucha confidencias. Los finales siguen reconociendo acciones de apoyo adulto, límites digitales o pasos pendientes. El epílogo incluye las cuatro voces.

El contenido está en `data/narrative/coral_story_v0_2.json`. Sigue siendo una propuesta editorial, sin rúbrica oficial ni puntuación educativa. No se requieren recursos gráficos nuevos.

Las partidas coral v0.1 se migran a v0.2 conservando decisiones, confidencias, preferencias y acciones de protección. Si estaban en D2–D4, se retoma D2 para permitir las conversaciones que antes no podían visitarse. Las conversaciones D2 ya completadas mantienen su estado. Los desenlaces ya terminados se conservan.

La prueba `CoralRoutesTests.tscn` recorre todo el grupo en tres órdenes diferentes, comprueba la disponibilidad simultánea de los cuatro personajes, el cierre explícito de jornadas, los tres finales, guardado entre compañeros, migración y prólogo sin definición anticipada. La suite general y las pruebas de IndexedDB también se ejecutaron correctamente.
