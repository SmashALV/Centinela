# Feedback de la profesora · implementación v0.38

Referencia: `C:/Users/fabri/Downloads/feedback_profesora_estado_del_juego.md`. Las sugerencias se contrastaron con las indicaciones directas del usuario: se conserva el texto completo y automático, con decisiones sin temporizador.

| Tema | Cambio aplicado |
| --- | --- |
| D0 y controles | Guías centrales antes de explorar habitación, patio y computadora. Indican el objetivo y las teclas. Se guardan y se recuperan tras recargar o pausar. |
| Continuidad | Antes de la PC se explica que las clases terminaron, Sofi volvió a casa e hizo sus tareas. |
| Aprendizaje | El comienzo presenta a Sofi y su rutina. Después del epílogo, los tres finales explican el grooming, las señales observadas y las posibilidades de apoyo. La devolución recuerda las respuestas de D2 a Camila, Mateo y Sebas, sin puntuación. |
| Tutoría | Una visita sin preocupaciones conocidas presenta el espacio y no cuenta como apoyo iniciado. Tras una confidencia, la conversación expresa el motivo concreto de la visita. No exige esperar a un encuentro ni reunir pruebas. |
| Lenguaje | Se sustituyó «límite digital» por acciones de bloqueo, silencio y privacidad. Se revisaron varias líneas nuevas para usar expresiones más cercanas; los textos recuperados permanecen intactos. |
| Identidad | Camila tiene cabello corto, pecas y ojos verdes en ilustración, avatar y mapa. Sofi y su interlocutor mantienen nombres visibles, con énfasis en quien habla. Los avatares de la presentación tienen sus nombres debajo. |
| Despedidas | Después de la conversación del patio, cuatro recorridos distintos y velocidades variables llevan a los amigos hacia distintas salidas. La pausa detiene su movimiento. |
| Cuarto | Armario más ancho, espejo y tocador, zapatero y TV; se mantienen libres las rutas principales. |
| Código | El código CTN se conserva en el guardado y no aparece en HUD, pausa ni ranuras. Se retiró de la pausa el mensaje técnico sobre configuración remota. |

Los guardados anteriores son compatibles: las guías se incorporan sin borrar decisiones ni cambiar el código. Las partidas ya concluidas mantienen su resumen; las nuevas líneas educativas se presentan al recorrer el epílogo. No se emiten nuevas puntuaciones ni se declara una rúbrica aprobada.

## Fuentes y revisión editorial

El cierre educativo se redactó tomando como referencia las páginas primarias [Unsafe contact and grooming, eSafety](https://www.esafety.gov.au/young-people/unsafe-contact) y [Grooming, National Office for Child Safety](https://www.childsafety.gov.au/about-child-sexual-abuse/grooming), consultadas el 29-10-2026. El texto distingue señales de una prueba concluyente, evita culpabilizar y mantiene el acceso a apoyo. Las referencias también están en `closing_sources` del JSON narrativo.

La decisión académica pendiente con Quintana y los protocolos de pretest, consentimiento de padres y aplicación con adolescentes son externos al juego. No se programaron reuniones a partir de las fechas relativas de la transcripción. La propuesta de trasladar el caso principal de Mateo a Sofi y el escenario de biblioteca quedan como opciones editoriales; no forman parte de esta revisión.

## Comprobación

`TeacherFeedbackTests.tscn` cubre las guías y su recuperación, movimiento bloqueado antes de exploración, transición temporal, código oculto pero conservado, despedidas, tutoría, devolución en F01/F02/F03 y nuevas texturas. También pasaron la suite general, recorridos compartidos, presentación automática, IndexedDB y la comparación de textos recuperados. La prueba Web captura `bedroom_guide.png`, `bedroom_decorated.png`, `camila_identity_v2.png` y `closing_education.png` en `build/web/`.

Los archivos gráficos y sus prompts se detallan en [Camila v2](CAMILA_V2_ASSETS_2026-10-29.md).
