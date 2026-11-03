# Registro de decisiones — Centinela 2.0

**Estado:** 250 decisiones cerradas al 27/10/2026. No se abrirán nuevas preguntas de diseño.

El contenido exacto individual de GAME-001 a GAME-212 no se recuperó en forma literal; su definición funcional está consolidada por subsistemas en el GDD. No inventar valores históricos.

| GAME | Opción | Decisión |
|---|---|---|
| GAME-213 | C | inactividad >120 s descriptiva por contexto |
| GAME-214 | B | Godot web |
| GAME-215 | A | UI Godot |
| GAME-216 | A | UI modular |
| GAME-217 | A | una ventana principal |
| GAME-218 | C | Esc contextual |
| GAME-219 | C | fullscreen opcional |
| GAME-220 | B | escala proporcional |
| GAME-221 | B | anclajes |
| GAME-222 | B | mínimo y pausa |
| GAME-223 | A | escenas reutilizables |
| GAME-224 | A | JSON diario |
| GAME-225 | A | índices secuenciales |
| GAME-226 | B | versionado+migración |
| GAME-227 | B | validador |
| GAME-228 | A | GDScript |
| GAME-229 | B | manual+headless |
| GAME-230 | B | simulación de rutas |
| GAME-231 | B | cobertura crítica |
| GAME-232 | B | tests JSON |
| GAME-233 | B | test save/load |
| GAME-234 | A | snapshot JSON |
| GAME-235 | B | IndexedDB stores |
| GAME-236 | B | atomicidad |
| GAME-237 | B | confirmar antes de avanzar |
| GAME-238 | A | una pestaña |
| GAME-239 | B | lease renovable |
| GAME-240 | A | pestaña obsoleta se detiene |
| GAME-241 | B | WebBridge central |
| GAME-242 | B | protocolo JSON |
| GAME-243 | B | idempotencia y reintentos |
| GAME-244 | B | tres entornos |
| GAME-245 | B | CI/CD+aprobación |
| GAME-246 | B | versión congelada |
| GAME-247 | B | rollback |
| GAME-248 | A | backup Supabase disponible |
| GAME-249 | A | pruebas técnicas internas |
| GAME-250 | C | desarrollo híbrido |

**Regla de precedencia:** acuerdos más recientes corrigen las iteraciones anteriores y no implican reiniciar diseño. Cualquier cambio posterior se formaliza como incidencia o ADR de implementación, no como GAME-251.

## Actualización P2 · 28/10/2026

Por solicitud directa del usuario, el límite de la partida MOBA pasa de 180 a **60 segundos**. Se conservan la cuenta atrás de 3 segundos, los avisos de últimos 30 y 10 segundos y el desempate por estructuras y daño efectivo. La navegación IA usa el centro de cada casilla y evita marcar como sólidas las casillas libres contiguas al muro. Los héroes heridos avanzan hasta su zona segura antes de esperar la recuperación.
