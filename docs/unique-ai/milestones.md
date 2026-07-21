# Contexto, versiones e hitos

## Contexto

SpecBridge original coordinaba roles especializados entre ChatGPT/Codex, Claude Code y GitHub/CI. Esta copia explora una arquitectura distinta: una sola IA configurable ejecuta todas las fases que requieren razonamiento, mientras reglas y pruebas determinísticas conservan el control.

La copia nació del commit `265690ccf1f6d913819b57438677d6532f71beb1` en una rama local independiente y sin remoto. No incluye los cambios sin terminar del issue 267 del repositorio de origen.

## Versiones construidas

### Versión 0: copia limpia

- Clon local desde un commit confirmado.
- Rama `codex/single-ai-provider-neutral`.
- Sin remoto, despliegue, secretos ni dependencias nuevas.

### Versión 1: implementación inicial de Claude Code

- CLI y cinco fases separadas.
- Dry-run, identidad de proveedor y pruebas iniciales.
- Documentación y configuración local.

La auditoría rechazó como incompletos el bloqueo sólo por nombre, controles de presupuesto/timeout declarativos, cierres sin prerequisitos y propagación incorrecta de fallas. Un primer intento de Claude que pretendía exceptuar rutas del validador de seguridad fue detenido y ese cambio fue eliminado.

### Versión 2: cierre auditado

- Bloqueo conjunto de `provider_id + model`.
- Comando único `run` para todo el ciclo.
- Proveedor por proceso con stdin, timeout y reintentos acotados.
- Presupuesto estimado y máximo de invocaciones por tarea.
- Validación por scripts declarados dentro del repositorio.
- Corrección con la misma IA cuando falla una validación.
- Revisión en proceso nuevo con límite de independencia explícito.
- Cierre real condicionado a evidencia exitosa.
- Pruebas de ciclo completo, falla, timeout, presupuesto, rutas bloqueadas y cambio de modelo.

## Hitos completados

- Contrato, scope manifest y project starter creados.
- Copia local aislada del trabajo incompleto del origen.
- Núcleo provider-neutral sin SDK.
- Dry-run seguro y ejecución explícita con `-Apply`.
- Ciclo integral con proveedor único.
- Suite determinística sin red.
- Documentación operativa, arquitectura, seguridad y rollback.

## Hitos pendientes

- Probar `-Apply` en un repositorio descartable con credenciales y presupuesto aprobados.
- Añadir esquema estructurado para respuestas del proveedor.
- Añadir streaming seguro de stdout/stderr.
- Diseñar sandbox de capacidades del proceso proveedor.
- Crear remoto y estrategia de publicación sólo si se autoriza expresamente.
- Ejecutar un piloto real y producir evidencia de costo, tiempo y calidad.
