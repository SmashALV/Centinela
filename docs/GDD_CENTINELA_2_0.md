# CENTINELA 2.0
## Game Design Document (GDD) consolidado — versión 1.0 de especificación

**Estado:** diseño cerrado (GAME-001 a GAME-250); documento de consolidación para implementación, no producto construido.  
**Fecha de corte:** 27 de octubre de 2026.  
**Motor:** Godot 4 / GDScript · **Plataforma:** navegador de escritorio · **Datos:** IndexedDB + Supabase PostgreSQL.  
**Ámbito:** juego serio de prevención del grooming en contextos de videojuegos en línea para adolescentes de 13 a 16 años, usado en investigación supervisada.  
**Estrategia elegida en GAME-250:** C, desarrollo híbrido: arquitectura base y entregas jugables verificables.

> **Control de fidelidad.** Esta especificación reúne los acuerdos cuya formulación es recuperable en el historial disponible. No se conserva aquí la transcripción íntegra y literal de todos los parlamentos, opciones y microeventos aprobados anteriormente. Se preservan las secuencias y reglas conocidas; **no se rellenan con ficción los diálogos faltantes**. Los archivos narrativos definitivos deberán transcribirse del guion aprobado, conservando sus versiones. Tampoco se afirma disponer de una lista individual exhaustiva de GAME-001 a GAME-212: se incorpora la trazabilidad por subsistemas y el registro explícito GAME-213–250.

---

# 1. Resumen ejecutivo y visión

**Concepto:** Centinela 2.0 es una aventura narrativa 2D top-down, con estética pixel art inspirada en los RPG de exploración clásicos, diálogos con retratos anime, un celular interactivo y una partida breve de un MOBA ficticio de una sola línea. La experiencia presenta señales progresivas de grooming y permite practicar decisiones de reconocimiento, límites, protección de datos y búsqueda de apoyo, sin culpabilizar a la víctima. 

**Premisa:** Sofía «Sofi» Castillo, de 15 años, comparte su vida escolar y su afición a los videojuegos con Mateo, Bruno, Camila y Sebas. En un entorno de juego en línea aparece «Kairo», un desconocido que afirma tener aproximadamente la misma edad y se aproxima progresivamente a Mateo mediante un regalo digital, peticiones de secreto, manipulación y una propuesta de encuentro. El relato presenta alternativas protectoras, intermedias y no resueltas; **no representa un encuentro real**.

**Público:** adolescentes de 13–16 años en un contexto académico supervisado; uso principal en PC con teclado y ratón; no se orienta al consumo abierto sin supervisión como objetivo de investigación, aunque la URL ordinaria del juego no exige credenciales de estudiante.

**Duración objetivo:** 20–30 minutos de relato completo; partida MOBA de máximo 60 segundos, según la actualización solicitada el 28/10/2026. El tiempo de interacción real puede variar según lectura, pausas y exploración.

**Objetivo pedagógico:** apoyar el reconocimiento temprano de conductas de grooming y el ejercicio de respuestas de protección. **No constituye una herramienta diagnóstica**, no identifica agresores reales, no analiza comunicaciones privadas auténticas y no sustituye el apoyo de profesionales o adultos de confianza.

# 2. Alcance y límites

**Dentro del alcance:** cinco jornadas narrativas (Día 0 a Día 4); exploración top-down; objetos obligatorios y opcionales; diálogos ramificados; mensajes persistentes; captura de chat mostrada por Mateo; una partida MOBA 5v5 controlada por IA; tres finales; tres ranuras locales; captura de métricas educativas seudonimizadas; dashboard administrativo; exportación CSV/XLSX; tres entornos y proceso de publicación validado.

**Fuera del alcance aprobado:** juego multijugador real; chats con usuarios reales; análisis de grooming mediante IA/NLP; contacto con extraños de verdad; voz grabada o retransmitida; registro de estudiantes con correos/nombres; exposición de notas educativas a los menores; vinculación individual de pretest/postest con métricas del juego; telemetría comercial o seguimiento publicitario.

**Condición de sensibilidad:** mensajes simulados apropiados para menores, sin descripciones sexualmente explícitas, solicitud real de datos personales ni reproducción de técnicas en detalle innecesario. El guion debe mostrar rutas de protección sin sancionar o avergonzar a quien elija una respuesta menos segura.

# 3. Personajes y roles

| Personaje | Edad | Rol / función |
|---|---:|---|
| Sofía «Sofi» Castillo | 15 | Protagonista controlada por el estudiante; observa, conversa y decide cómo intervenir. |
| Mateo Salazar | 15 | Amigo sobre el que recaen las aproximaciones de Kairo. |
| Bruno Paredes | 16 | Integrante del grupo y del equipo de juego. |
| Camila Ramos | 15 | Integrante del grupo; participa en la reacción posterior al MOBA. |
| Sebastián «Sebas» León | 14 | Integrante del grupo y del equipo de juego. |
| Kairo | No verificada | Persona remota desconocida que afirma tener 15–16 años; su identidad y edad no se confirman. |
| Adulto de confianza | — | Figura de apoyo (orientador escolar y/o madre) en las rutas protectoras. |

Las cinco personas del grupo constituyen el equipo aliado del MOBA: Mateo, Bruno, Sofi, Camila y Sebas. Kairo participa en las interacciones digitales, no como contacto de confianza del grupo personal ni como integrante permanente del chat privado.

# 4. Estructura narrativa, progresión y finales

## 4.1 Día 0 — Presentación y partida introductoria

1. Inicio en la habitación de Sofi. Interacciones obligatorias: alarma y mochila; opcionales: escritorio, PC y fotografía.
2. Transición al patio escolar y presentación de amistades.
3. En la noche, interacción con la computadora personal y conversaciones digitales; acceso a un MOBA ficticio tras el chat grupal.
4. Selección de clase y partida 5v5; resultado registrado descriptivamente.
5. Reacción posterior de Camila. Existen nueve variantes de diálogo según el resultado/contexto definido previamente; **su texto literal queda referenciado al guion fuente y no se recrea aquí**.

## 4.2 Día 1 — Aparición de Kairo

Kairo se presenta como jugador conocido en el entorno de juego, se introduce de manera limitada como invitado temporal de lobby y afirma una edad semejante a la del grupo, sin acreditarla. Las conversaciones y observaciones iniciales permiten reconocer señales aún ambiguas. No se le integra automáticamente en los contactos personales de Sofi ni en su chat privado de amistades.

## 4.3 Día 2 — Regalo y privacidad

En el exterior del colegio, junto a un árbol, Mateo muestra directamente a Sofi una **captura real dentro de la ficción en su teléfono**. Kairo ofrece una skin/regalo virtual y ha mantenido conversaciones privadas con Mateo. Sofi puede reaccionar con distinto grado de interés y cautela. Existen referencias parciales recuperadas de parlamentos aprobados, pero el conjunto de texto y posiciones no está íntegro aquí: debe incorporarse desde el guion maestro sin reformular.

## 4.4 Día 3 — Presión y manipulación

Aumentan peticiones de confidencialidad, apelaciones emocionales y conductas de aislamiento o presión. Las conversaciones deben permitir distinguir amabilidad de manipulación y promover límites seguros. Las decisiones afectan variables narrativas establecidas; no modifican retroactivamente respuestas ya registradas.

## 4.5 Día 4 — Propuesta de encuentro y desenlace

Kairo propone un encuentro secreto; el encuentro **no sucede ni se representa**. Las alternativas de Sofi y Mateo conducen a tres desenlaces narrativos definidos a continuación. El contenido se aborda sin culpabilización y con oportunidad de pedir ayuda a un adulto confiable.

| Final | Estado del relato | Interpretación de diseño |
|---|---|---|
| **F01** | Protector | Reconocimiento de señales, establecimiento de medidas de protección y búsqueda de ayuda confiable. |
| **F02** | Intermedio | Se establecen límites, pero no se concreta el apoyo de un adulto confiable. |
| **F03** | No resuelto | La situación permanece abierta y requiere atención; no se muestra un encuentro. |

**Importante:** el final es una variable narrativa descriptiva y no reemplaza la puntuación educativa calculada por dimensiones.

## 4.6 Estado y ramificación

Variables narrativas conocidas: `CONFIANZA_MATEO_SOFI`, `RECONOCE_MANIPULACION` y banderas de progresión por jornada, escena y decisión. El motor usa conversaciones JSON con posiciones numéricas; cada opción dirige a otra posición o evento, sujeta a condiciones. Una posición no es un identificador educativo estable. Las decisiones evaluables conservan `decision_id` únicos y versionados.

**Guion canónico pendiente de transcripción documental:** líneas completas D0–D4, alternativas literales, posiciones finales y variantes de Camila. La implementación deberá fallar en validación si faltan estos contenidos, sin inventarlos con texto generado automáticamente.

# 5. Bucle de juego, exploración y controles

**Bucle principal:** explorar → interactuar con persona u objeto → leer conversación/celular → seleccionar una respuesta cuando proceda → confirmar decisiones significativas → actualizar estado y evento atómicamente → desbloquear la siguiente escena.

| Entrada | Acción |
|---|---|
| WASD | Desplazamiento de Sofi en 8 direcciones con normalización de diagonales; animaciones/orientación cardinal. |
| F | Interactuar con objetos o personajes dentro del radio previsto. |
| E | Abrir/cerrar el celular cuando esté permitido; no durante MOBA ni encima de diálogos obligatorios. |
| Tab | Abrir/consultar el panel del objetivo y las pistas escalonadas. |
| 1/2/3 | Selección directa de alternativas narrativas. |
| Flechas arriba/abajo + Enter | Seleccionar y confirmar navegación de opciones, con confirmación neutral adicional cuando corresponda. |
| P | Pausar desde juego, diálogo o MOBA; restablecer el contexto al continuar. |
| Esc | Función contextual: cerrar teléfono/objetivos, volver desde ajustes, cancelar una confirmación o controlar pausa, sin saltar diálogos obligatorios. |
| Ratón | Selección de interfaz; en MOBA, apuntar y atacar con clic izquierdo sostenido o puntual. |
| Q | Habilidad de la clase elegida durante el MOBA. |

**Objetivos:** mensaje breve en HUD y detalle mediante Tab; se resaltan de forma discreta objetos obligatorios, no opcionales. Las pistas opcionales ofrecen dos niveles crecientes de concreción sobre navegación, nunca indican la “respuesta correcta” frente al grooming.

**Diálogos:** panel oscuro opaco de alto contraste, texto claro, nombre de hablante destacado, retrato anime con cinco expresiones. Velocidad lenta/normal/rápida; primer clic revela texto íntegro y siguiente clic avanza. No existe función de saltar escenas completas. Historial de la conversación actual, distinto al historial persistente de chats del celular.

**Celular:** icono inferior izquierdo con notificación; interfaz oscura con Chats y Contactos; conversaciones consultables, desplazables y persistentes. Los mensajes obligatorios deben completarse antes de avances que dependan de ellos. Los mensajes se pueden consultar de nuevo sin repetir eventos educativos.

**Pausa:** automática ante pérdida de foco o ventana insuficiente; manual con P. En reactivación se requiere acción explícita «Continuar» (nunca reanudar automáticamente). Durante MOBA detiene cronómetro y combate. El aviso de ventana insuficiente solo dirá «Amplía la ventana del navegador o activa la pantalla completa para continuar jugando»; **no mostrará «Tu progreso está protegido»**, texto retirado posteriormente.

**Pantalla completa:** opcional, nunca obligatoria. Escalado proporcional con `nearest-neighbor`, márgenes cuando sea necesario. El MOBA mantiene viewport lógico de 768×448 y 24×14 tiles. UI Godot `Control` anclada y adaptable, textos pequeño/mediano/grande, sin contenido educativo recortado. Tamaño mínimo exacto se fija tras pruebas funcionales; bajo ese umbral se pausa.

# 6. Minijuego MOBA ficticio 5v5: especificación de combate

## 6.1 Arena, equipos y cámara

| Parámetro | Regla aprobada |
|---|---|
| Tipo | Una única línea horizontal central, sin jungla ni tres líneas. |
| Arena | 36×20 casillas de 32 px = 1152×640 px lógicos. |
| Cámara | Vista 24×14 casillas = 768×448 px lógicos, seguimiento suave de Sofi. |
| Duración máxima | 60 segundos por partida. |
| Equipos | 5 héroes aliados / 5 enemigos controlados por IA, salvo Sofi. |
| Aliados | Mateo, Bruno, Sofi, Camila y Sebas, desplegados verticalmente con Sofi centrada. |
| Enemigos | 3 atacantes, 1 defensor y 1 soporte. |
| Estructuras | Por lado: torre exterior → torre interior → base. |
| Obstáculos | Sólidos, bloquean movimiento, visión y proyectiles según geometría. |
| Pasos laterales | Se conservan rutas libres de al menos 4 casillas para evitar bloqueos totales. |
| Colisión entre héroes | No se bloquean mutuamente. |
| Ruinas | Torre destruida pasa a ruina sólida de 2×2 casillas. |

El jugador elige clase antes de iniciar; cuenta atrás 3, 2, 1. Se muestran objetivo y advertencias temporales de últimos 30 y 10 segundos. El combate no puede ser interrumpido por diálogos narrativos.

## 6.2 Movimiento, estadísticas generales y ataques

| Parámetro | Valor |
|---|---:|
| Salud máxima por héroe | 80 HP |
| Velocidad de movimiento | 3 casillas/segundo |
| Daño del ataque básico | 12 HP |
| Intervalo básico | 1,0 segundo |
| Alcance básico | 6 casillas |
| Velocidad de proyectil normal | 12 casillas/segundo |
| Movimiento | WASD 8 direcciones normalizadas |
| Apuntado | Cursor del ratón |
| Disparo | Clic izquierdo o mantenido, respetando cadencia |

**Habilidades Q por clase**:

| Clase | Fantasía visual | Habilidad Q | CD / condiciones |
|---|---|---|---|
| Atacante | Arquero | Proyectil penetrante de 24 de daño, golpea hasta 2 héroes enemigos; contra estructuras inflige solo 12. | CD 12 s; alcance 8 tiles; velocidad 16 tiles/s. |
| Defensor | Caballero | Escudo de 20 HP a aliado objetivo dentro de 5 tiles, o 10 HP a sí mismo. | CD 16 s; 4 s de duración; no exige línea de visión. |
| Soporte | Bardo | Aumenta 25 % velocidad de Sofi y aliados en radio de 3 tiles. | CD 9 s; dura 5 s; no acumula, solo refresca. |

**Escudos:** apilamiento temporal permitido e independiente, consumo prioriza la expiración más próxima. La inmunidad temporal de respawn es distinta a escudo. La habilidad del Defensor no requiere línea de visión, según aprobación.

## 6.3 IA, curación, derrota y reaparición

IA aliada y enemiga sigue principios simétricos: atacar héroes y objetivos vulnerables, defender estructuras, perseguir cuando corresponda, retroceder al alcanzar ≤24 HP, buscar posición segura para regenerar. Cada héroe recupera 4 HP/s tras 4 s sin infligir ni recibir ataque; se cura hasta al menos 64 HP en seguridad antes de retornar según IA. Cuando un héroe muere reaparece 3 s después con 80 HP y habilidad Q disponible. Tras revivir disfruta 1 s de invulnerabilidad, que se anula si efectúa ataque básico; utilizar Q no cancela esa protección.

Si Sofi muere, la cámara sigue al compañero vivo más cercano, pudiendo cambiar si también muere; vuelve a Sofi al reaparecer.

## 6.4 Estructuras, torretas y condiciones de victoria

| Estructura | HP | Ataque / regeneración |
|---|---:|---|
| Torre exterior | 240 | Dispara 12 daño cada 1,5 s, alcance 7 tiles; sin regeneración. |
| Torre interior | 240 | Igual que exterior; sin regeneración. |
| Base | 400 | No ataca; regenera 4 HP/s tras 5 s sin daño efectivo. |

Los proyectiles de torres son dirigidos al héroe enemigo visible más cercano, viajan a 12 tiles/s y pueden impactar obstáculos o ruinas. El orden de vulnerabilidad es **torre exterior → interior → base**; ataques contra estructuras aún bloqueadas no cuentan como daño efectivo. La victoria inmediata se produce al destruir la base enemiga; la derrota si cae la propia. Tras 60 s sin destrucción de base, se comparan primero torres enemigas destruidas y luego daño estructural acumulado **efectivo** (incluido daño luego regenerado por base); igualdad de ambos criterios: empate. El resultado del MOBA se registra descriptivamente y no aumenta ni reduce la puntuación educativa de grooming.

**Interrupción:** si el navegador se cierra a mitad de partida, al continuar se mantiene la clase elegida pero se reinicia íntegramente el estado del combate tras un nuevo 3–2–1; no se restauran posiciones, HP o cronómetro a mitad de MOBA. Solo se registra resultado final al terminar; intentos reiniciados no deben confundirse con resultado completado.

# 7. Diseño educativo y rúbrica de evaluación

## 7.1 Dimensiones

| Código | Dimensión | Evidencia esperada |
|---|---|---|
| D1 | Reconocimiento de señales de grooming | Distinguir patrones de aproximación y conductas de riesgo. |
| D2 | Reconocimiento de manipulación emocional | Identificar secretos, culpa, presión y dependencia. |
| D3 | Privacidad y establecimiento de límites | Proteger información, rechazar solicitudes y marcar límites. |
| D4 | Búsqueda de ayuda de adultos confiables | Reconocer cuándo y cómo solicitar apoyo apropiado. |

**Asignación de puntos por respuesta evaluable:** 0 = no evidencia la conducta deseada; 1 = evidencia parcial; 2 = evidencia clara. Cada ítem pertenece a dimensión y versión de rúbrica definidas por el equipo académico. Esta escala **no se expresa como castigo moral** ni establece diagnóstico o culpabilidad.

**Cálculo:** para dimensión con cobertura suficiente, `score_d = 100 * suma(puntos_obtenidos)/suma(puntos_posibles_de_items_evaluados)`; global con las cuatro dimensiones evaluables: `0.25*(D1 + D2 + D3 + D4)`. Registrar cobertura y distinguir «sin información/no evaluado» de 0 puntos; no imputar cero a una decisión que el estudiante no pudo responder.

**Reglas de implementación:** el navegador no calcula calificación oficial ni muestra puntuación al estudiante. Supabase calcula con una rúbrica aprobada, versionada y bloqueada por partida; una recalificación excepcional debe ser explícita y auditada. Las pistas, pausas, tiempo, exploración, clase del MOBA, victoria/derrota y final narrativo no alteran directamente el puntaje.

## 7.2 Integración con investigación y pre/postest

La investigación considera pretest y postest **externos al juego**, con análisis a nivel grupal y **sin enlace individual** entre puntajes del instrumento y UUID/código de partida. Las métricas del juego son medidas comportamentales complementarias, no un sustituto del instrumento de autopercepción. La ficha de investigación existente describe, como propuesta anterior, una medición OSAAS y pruebas para muestras relacionadas. Debe revisarse con la metodología definitiva: una comparación pareada requiere que los resultados del pretest y postest estén pareados entre sí por un mecanismo autorizado; **no se debe afirmar que existe ese emparejamiento ni aplicarse automáticamente una prueba pareada sin comprobarlo**.

# 8. Telemetría educativa y variables descriptivas

**Eventos educativos:** identificadores `event_id` UUID y secuencia estrictamente creciente por partida; `decision_id`, `choice_id`, versión narrativa/rúbrica, jornada/escena, contexto y marca temporal. El backend valida autorización, estructura, transición narrativa y elegibilidad del evento; rechaza duplicaciones sin duplicar puntaje. El texto sensible de comunicaciones reales o nombres de estudiantes no se recopila.

**Métricas descriptivas:** día, escena, progreso, tiempo efectivo total y por jornada; tiempo transcurrido con juego abierto (incluye pausas, excluye pestaña cerrada); número de ayudas consultadas; eventos de pausa; final F01/F02/F03; resultado MOBA (victoria/derrota/empate) y condición de finalización; sesiones de juego iniciadas e incompletas. Episodios de **inactividad sin teclado ni ratón ≥120 s** con videojuego sin pausar, separados por exploración, diálogos/chats y MOBA, con cantidad y duración; se registran descriptivamente, sin atribuir desatención ni afectar nota.

**Sincronización:** persistencia local de eventos antes de continuar en decisiones evaluables; envío en lotes de hasta 10 cada aproximadamente 10 s o anticipado en umbrales y hitos (fin del día, final del MOBA, fin narrativo). Confirmaciones individuales permiten retirar solo eventos reconocidos. Errores transitorios reintentan con retroceso exponencial y jitter (referencias 2,4,8,16,32 s). Errores permanentes de validación no se reintentan indefinidamente. El final muestra estado de sincronización y botón de reintento sin revelar nota; se puede salir con carga pendiente. «Completo» solo si se han recibido y validado todos los números de secuencia hasta el último declarado.

# 9. Identidad, acceso y seguridad

**Estudiante:** no crea cuenta, nombre, correo ni contraseña, ni utiliza enlace personalizado. Cada ranura genera UUID interno y código visible seudónimo `CTN-XXXXXX`, mostrado en selección de partidas y pausa. La URL común permite entrar sin garantía automática de pertenecer a una cohorte autorizada.

**Investigador:** valida manualmente el código de cada participante desde el dashboard; estados «validado», «prueba», «no validado» con justificación y auditoría. Solo «validado» participa en análisis primario. Grupos de sesión `SES-001` y sucesivos, nombre opcional descriptivo, fecha/hora `America/Lima`, estado planificada/en curso/cerrada; al cerrar no se edita directamente, reapertura auditada.

**Autenticación técnica:** cada inicio de sesión del juego obtiene nueva identidad Supabase Auth anónima. La partida se recupera con credencial secreta aleatoria por guardado, **distinta del código CTN**, emitida por servidor y almacenada localmente separada del JSON narrativo. El backend verifica prueba de posesión, mantiene hash del secreto y revoca derechos anteriores de escritura al transferir a la identidad anónima nueva. Acceso al mismo perfil del navegador puede exponer esos datos: IndexedDB **no es una bóveda segura**. Cuentas anónimas revocadas pueden depurarse según política de retención y referencias, sin borrar eventos académicos.

**Backend:** Edge Functions seguras para validación, autorización, scoring e ingestión; secret `service_role` jamás en cliente. Aplicar RLS, validación por partida, limitación de abuso, auditabilidad y mínimos privilegios. Dashboard con una cuenta administrativa compartida según decisión previa; reconocer que limita atribución individual del auditor, por lo que se registra acción y hora, y se recomienda control de acceso reforzado sin cambiar el alcance aprobado.

# 10. Arquitectura técnica de la solución

## 10.1 Plataforma, capas y tecnologías

| Capa | Herramienta aprobada | Función |
|---|---|---|
| Render y lógica jugable | Godot 4, GDScript | Escenas 2D, combate, actores y UI. |
| UI | Godot `Control` / `CanvasLayer` | Menús, celular, diálogos, HUD, objetivos y pausa. |
| Narrativa | JSON por día + `NarrativeManager.gd` | Flujo, condiciones, elecciones, eventos. |
| Persistencia | IndexedDB vía JavaScript | Slots, snapshots, cola, credenciales y sincronización. |
| Puente | `WebBridge.gd` ↔ `web_bridge.js` | Solicitudes asíncronas JSON versionadas. |
| Backend | Supabase Auth + Edge Functions + PostgreSQL | Identidad anónima, validación, scoring, eventos y reportes. |
| Dashboard | Aplicación web independiente | Sesiones, validación, análisis y exportación. |
| CI/CD | Flujo automatizado con aprobación | Prueba, exportación web, staging y producción. |

## 10.2 Escenas y módulos Godot

`res://scenes/world/SofiBedroom.tscn`, `SchoolCourtyard.tscn`, `SchoolExterior.tscn`, `ComputerScene.tscn`, `res://scenes/moba/MOBAArena.tscn`. Estas son denominaciones técnicas **propuestas para implementación**, no nombres de archivos ya existentes. Reutilizar escenarios en distintos días; `NarrativeManager.gd` mantiene el estado central.

Escenas UI independientes: `DialogueUI.tscn`, `PhoneUI.tscn`, `PauseMenu.tscn`, `ObjectiveUI.tscn`, `CombatHUD.tscn`, `MainMenu.tscn`. `UIManager.gd` permite una sola ventana principal activa, con pausa superpuesta y restauración exacta. El enfoque de teclado se asigna a la capa activa; escenas obligatorias no se saltan con `Esc`.

## 10.3 Narrativa JSON y validaciones

Datos en `res://data/narrative/day_0.json` a `day_4.json`, más `endings.json`. Las listas almacenan posición secuencial y ramifican a otros índices; una actualización del guion exige versionado explícito y mapeos de migración. `NarrativeMigrationManager.gd` puede convertir índices antiguos en equivalentes validados; conserva el guardado anterior si la migración falla. `NarrativeValidator.gd` revisa sintaxis, campos, índices destino, condiciones y finales alcanzables. Tests declarativos `res://tests/narrative/*.json` con `NarrativeTestRunner.gd` comprueban alternativas educativas, variables, los tres finales y condiciones críticas sin ejecutar el render. No se exige cobertura combinatoria exhaustiva. Se ejecutan manualmente y en Godot headless antes de despliegue; errores críticos bloquean publicación.

## 10.4 IndexedDB: stores y transacciones

| Object Store | Responsabilidad |
|---|---|
| `save_slots` | Ranura 1–3, UUID, código CTN, secuencia y metadatos de partida. |
| `save_snapshots` | Estado JSON versionado: día, escena, coordenadas, diálogos, variables, configuración/UI. |
| `event_outbox` | Eventos UUID aún pendientes/confirmaciones parciales. |
| `sync_status` | Última secuencia reconocida, errores y reintentos. |
| `save_credentials` | Credencial secreta de recuperación por guardado, nunca expuesta en logs. |

**Regla de atomicidad (GAME-236):** una decisión evaluable actualiza snapshot, secuencia y outbox en la **misma transacción IndexedDB**. Solo tras `transaction.oncomplete` se aplica el avance narrativo definitivo (GAME-237). Transacción fallida conserva respuesta temporalmente y permite reintento; nunca avanza confiando en escritura no confirmada. Otros guardados de ranuras no pueden verse alterados.

**Control multitab:** un propietario válido por partida, lease renovable, vencimiento, `tab_id` y generación de bloqueo (*fencing token*). La adquisición y la validación antes de cada escritura deben ser transaccionales; nueva pestaña solo adquiere bloqueo caducado y verificadamente disponible. Pestaña anterior reactivada se detiene y vuelve a menú; ni sobrescribe ni emite nuevos eventos. Las escrituras pendientes antiguas deben rechazarse por generación obsoleta.

## 10.5 WebBridge: protocolo y tratamiento de errores

Solicitud estándar con `protocol_version`, `request_id`, `operation`, `payload`; respuesta con `request_id`, `success`, `result` o `error.code`. `WebBridge` centraliza validación de contrato, correspondencia petición–respuesta y notificación a GDScript. `request_id` se mantiene en cada reintento lógico; JavaScript conserva marca de idempotencia persistente de operaciones de escritura (no solo en memoria) y distingue error transitorio de `LOCK_LOST`, `INVALID_REQUEST`, `PROTOCOL_MISMATCH` o `STORAGE_ERROR` permanente. Si respuesta se pierde después de commit, consultar efecto persistido antes de repetir; reintentos acotados, con detención segura al agotarlos.

Para exportación web, `JavaScriptBridge` de Godot orquesta funciones JS accesibles desde la página; IndexedDB es asíncrono. La versión exacta de Godot y navegador compatible se fijarán y probarán, sin suponer que todo soporte de escritorio equivale a soporte web.

## 10.6 Recuperación local

Tres ranuras independientes y autosave en hitos más snapshots finos. Guardado versionado por esquema, por contenido narrativo y por rúbrica. Al cerrar/reabrir se restaura exactamente escena, posición, diálogo, conversación y estado apropiado de interfaz; durante MOBA la recuperación se realiza reiniciando el combate con la misma clase, no recuperando HP/cronómetro. La finalización narrativa y la sincronización son estados independientes: `story_completed` no implica `sync_completed`.

# 11. Modelo funcional de Supabase y dashboard

## 11.1 Entidades de dominio (diseño lógico)

- **ResearchSession**: código SES, ventana horaria Lima, estado, justificaciones, responsables, versión de juego/narrativa/rúbrica.
- **ParticipantSave**: UUID, CTN visible, ranura local, condición de validación, identidad anónima autorizada, hash de credencial, versiones.
- **GameEvent**: event_id, save_id, sequence, tipo, payload validado, hora, versión y aceptación/rechazo.
- **RubricVersion / RubricItem**: dimensiones D1–D4, reglas de decisión y puntuación 0/1/2, vigencia/versionado inmutable.
- **EducationalScore**: sumas y porcentajes por dimensión, cobertura, global cuando procede, versión de rúbrica y auditoría de recálculo.
- **SyncReceipt**: secuencias recibidas, faltantes, última declarada, error y estado de cierre.
- **PublishedReport**: `SES-001 v1`, `v2`, instantánea inmutable de participantes/datos/rúbricas y aprobación de publicación.
- **AuditEvent**: validaciones, reaperturas, cambios de reportes, recuperación y errores operativos.

Esta lista es un **modelo lógico de diseño**, no un esquema SQL ya implementado. Nombres y relaciones de tablas se formalizarán durante la fase backend sin modificar sus obligaciones funcionales.

## 11.2 Dashboard del investigador

Autenticación por la cuenta administrativa compartida aprobada. Vistas: resumen de sesiones, lista de códigos CTN y estado de elegibilidad, progreso individual seudónimo, puntaje por cuatro dimensiones, decisiones y rúbrica, eventos descriptivos, alertas por lagunas de secuencia o rechazo, comparación de cohortes. Exportación a **CSV y XLSX** de: (i) puntajes generales, (ii) decisiones educativas y rúbrica, (iii) eventos descriptivos. No incluir en exportación tokens secretos, nombres ni conversaciones reales.

Estados de sesión planificada / en curso / cerrada, reapertura auditada. Eventos tardíos tras cierre se ingieren y validan, pero requieren decisión explícita para integrar reporte oficial. Publicación versionada con snapshots inmutables y justificación si existe ausencia de métricas, participantes no validados, partidas incompletas, rechazos o eventos tardíos.

# 12. Arquitectura visual y recursos

**Exploración:** sprites pixel art de cuatro orientaciones, tilemaps consistentes, interiores/exteriores escolares y domésticos, objetos interactivos destacados sutilmente. **Diálogos:** retratos anime con cinco expresiones por personaje relevante, estilos consistentes y panel opaco. **MOBA:** formas legibles de tres clases, dos equipos, proyectiles diferenciables, obstáculos que dejan 4 tiles de paso y ruinas 2×2. **UX:** textos de contenido con tipografía sans legible y elementos pixel decorativos; colores de alto contraste, tamaños de texto configurables y scrolling correcto.

**Audio:** música y efectos controlados por ajustes de pausa. No se requiere locución ni grabación de voz; indicadores audiovisuales no deben ser la única vía para comprender información educativa.

**No se adjuntan assets gráficos definitivos** en esta consolidación: la lista de necesidades define los contratos de producción sin afirmar que ya existen sprites, mapas o retratos exportados.

# 13. Requisitos no funcionales y calidad

- **Fiabilidad:** no pérdida silenciosa de decisiones educativas; atomicidad, idempotencia y reanudación controlada.
- **Consistencia:** versiones narrativas y de rúbrica identificadas, congeladas durante sesiones oficiales; reporte auditado.
- **Privacidad:** seudonimización, minimización de datos, sin chat real ni identificación nominal de menores.
- **Seguridad:** Edge Functions para operaciones privilegiadas, RLS, credenciales del backend ausentes del cliente, saneamiento de entradas y logs.
- **Usabilidad:** mouse+teclado; mensajes claros, pausa segura, no bloqueo por overlays, texto no recortado.
- **Compatibilidad:** exportación web Godot, PC de laboratorio, escalado proporcional y navegador bajo pruebas documentadas.
- **Mantenibilidad:** módulos por dominio; decisiones educativas data-driven y JSON validable; pruebas repetibles en modo headless.
- **Observabilidad:** errores por tipo de operación, secuencia y partida seudónima; sin divulgar secretos.
- **Recuperabilidad:** partidas locales verificadas, rollback compatible, respaldo Supabase según capacidades del plan contratado (GAME-248 A); no se presupone PITR o retención no comprobada.

# 14. Plan de lanzamiento y gobernanza del cambio

Tres entornos independientes **development**, **staging**, **production** con proyectos/configuración/credenciales aislados. Flujo CI/CD: validación JSON, pruebas de rutas y guardado, pruebas de integración, exportación web, despliegue staging, aprobación manual, promoción a producción. Ningún cambio se publica automáticamente durante una sesión de investigación. Corrección crítica requiere autorización, registro de incidencia y evaluación del impacto metodológico. Rollback controlado a compilación estable compatible, verificando migraciones de guardado y esquema de base de datos; no se revierte Supabase por desplegar una compilación anterior.

**Validación final elegida (GAME-249 A):** pruebas técnicas internas obligatorias, sin piloto supervisado como prerrequisito técnico de publicación. Esto **no elimina** consentimientos/asentimientos, revisión ética, derechos de menores y demás requisitos institucionales. La ficha de investigación anterior contempla juicio de expertos, instrumentos e hipótesis de medición: su aprobación metodológica se gestiona aparte, sin modificar aquí la selección A.

# 15. Matriz de pruebas y criterios de aceptación

| ID | Verificación de aceptación |
|---|---|
| QA-01 | Completar al menos una ruta del Día 0 al 4 y alcanzar F01/F02/F03 de forma coherente. |
| QA-02 | Todas las decisiones educativas evaluables y alternativas están cubiertas por pruebas definidas. |
| QA-03 | El validador JSON bloquea destinos inexistentes, variables desconocidas, decisiones duplicadas y migraciones inconsistentes. |
| QA-04 | Duración MOBA ≤60 s; tiempos de CD, daño, curación, torres y condiciones de victoria se corresponden con el GDD. |
| QA-05 | Pausa P/Esc, pérdida de foco, tamaño mínimo, menús superpuestos y texto ajustable sin saltar escenas. |
| QA-06 | Después de guardado+reinicio, el snapshot y las variables equivalen al estado anterior; MOBA reinicia con clase retenida. |
| QA-07 | Fallo en transacción IndexedDB impide avanzar y no genera evento parcial. |
| QA-08 | Dos pestañas no escriben a la vez en el mismo save; pestaña con fencing antiguo no puede guardar. |
| QA-09 | Duplicado de request_id/event_id produce a lo sumo un evento aceptado y una decisión aplicada. |
| QA-10 | Reintentos offline, acuses parciales y llegada fuera de orden no generan falsos `sync_complete`. |
| QA-11 | Solo backend calcula D1–D4 y global; estudiante no ve nota, tiempo o MOBA no altera scoring. |
| QA-12 | Sesión cerrada y eventos tardíos no alteran reporte publicado sin aprobación y nueva versión. |
| QA-13 | Exportaciones del dashboard seudonimizadas sin credenciales secretas. |
| QA-14 | Versión staging aprobada antes de producción; rollback evalúa compatibilidad. |
| QA-15 | El juego no reproduce contenido explícito ni permite contacto/chat con personas reales. |

# 16. Trazabilidad de decisiones y cierre

**GAME-250 (C) — resolución final:** estrategia híbrida: arquitectura base estable más entregas jugables; se implementa un recorrido inicial del Día 0 con MOBA, interfaz y persistencia antes de desarrollar gradualmente el resto. **No quedan decisiones de diseño por someter al usuario**; los detalles técnicos menores se resolverán en Codex conforme a estas restricciones y se registrarán como decisiones de implementación, no como preguntas adicionales.

**Registro reciente:** GAME-213 C (inactividad >120 s descriptiva por contexto), 214 B (Godot web), 215 A (UI Godot), 216 A (UI modular), 217 A (una ventana principal), 218 C (Esc contextual), 219 C (fullscreen opcional), 220 B (escala proporcional), 221 B (anclajes), 222 B (mínimo y pausa), 223 A (escenas reutilizables), 224 A (JSON diario), 225 A (índices secuenciales), 226 B (versionado+migración), 227 B (validador), 228 A (GDScript), 229 B (manual+headless), 230 B (simulación de rutas), 231 B (cobertura crítica), 232 B (tests JSON), 233 B (test save/load), 234 A (snapshot JSON), 235 B (IndexedDB stores), 236 B (atomicidad), 237 B (confirmar antes de avanzar), 238 A (una pestaña), 239 B (lease renovable), 240 A (pestaña obsoleta se detiene), 241 B (WebBridge central), 242 B (protocolo JSON), 243 B (idempotencia y reintentos), 244 B (tres entornos), 245 B (CI/CD+aprobación), 246 B (versión congelada), 247 B (rollback), 248 A (backup Supabase disponible), 249 A (pruebas técnicas internas), 250 C (desarrollo híbrido).

**Restricción de trazabilidad:** el registro literal 001–212 no está reconstruido línea por línea en la documentación accesible. Los subsistemas se consolidan de las decisiones recuperables; los cambios posteriores prevalecen sobre antecedentes anteriores. Evitar atribuir un número GAME específico a una regla cuando no consta con certeza.

# 17. Concordancia con la ficha académica y cuestiones documentales

La ficha `Ficha_de_Investigacion_CIS_2026_v5 (5).docx.pdf` disponible en el proyecto describe una iteración académica anterior: escenarios de análisis de chats, clasificaciones seguro/sospechoso/alto riesgo, posibles elecciones React/Firebase, y propuesta de revisión por especialistas. **No equivale al alcance jugable definitivo** de cinco días con Sofi y un MOBA construido en Godot/Supabase. La ficha y su apartado metodológico deberán alinearse formalmente al proyecto desarrollado antes de presentar documentación definitiva de investigación. Esto no significa revertir decisiones GAME aprobadas.

Aspectos a conciliar en el expediente académico, sin abrir nuevas preguntas de GDD: (1) método efectivo de emparejamiento pre/postest y elección correcta de contrastes estadísticos; (2) juicios de expertos y autorizaciones éticas requeridas por el protocolo de investigación, diferenciadas de GAME-249; (3) redacción del objetivo y del rol del estudiante conforme al juego narrativo; (4) herramienta real Godot/Supabase; (5) instrumentos, rúbrica y validez de contenido; (6) derechos, consentimiento y asentimiento.

# 18. Entregables para Codex

Ver el documento complementario `PLAN_CODEX_CENTINELA_2_0.md` para fases, rutas del repositorio, pruebas de aceptación, Definition of Done y prompts listos para ejecutar. El paquete contiene también `AGENTS.md`, checklist de integración y plantillas estructurales **no canónicas** (nunca reemplazan al guion real).
