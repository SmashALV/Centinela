# Gestión de ranuras · 0.29.0-preview

Cada una de las tres ranuras muestra **Continuar/Nueva**, **Rehacer** y **Borrar** en el menú. Rehacer y Borrar se habilitan solo cuando existe un guardado y muestran una confirmación que puede cancelarse con **Esc**. Rehacer crea un código de partida nuevo y abre el prólogo; Borrar deja la ranura disponible para una partida nueva.

En Godot nativo se retiran el guardado principal y su copia local. En Web, cada operación comprueba el bloqueo de la ranura y modifica IndexedDB en una transacción. El reinicio asigna un `save_id` nuevo y secuencia cero. Ambas operaciones limpian credenciales, estado de sincronización, eventos pendientes y registros de solicitudes locales de esa ranura, sin afectar las otras dos. Las generaciones anteriores del bloqueo quedan invalidadas.

Desde la pausa del MOBA se puede salir al menú. Si se vuelve a abrir la misma ranura sin rehacerla, el combate interrumpido comienza desde el inicio según la regla de reanudación vigente.

Estas opciones administran los datos **locales**. Si en el futuro se activa el backend, los registros ya enviados al servidor requieren un flujo de eliminación remoto separado.
