# SpecBridge Unique IA

SpecBridge Unique IA es una variante local y provider-neutral de SpecBridge. Un único `provider_id` y un único `model` configurados realizan planificación, implementación, corrección y revisión en una sesión nueva. El cierre se decide con evidencia determinística; no requiere una segunda IA.

## Estado actual

El MVP local está implementado en PowerShell 5.1, sin SDK ni dependencias nuevas. Incluye:

- bloqueo inmutable de `provider_id + model` por tarea;
- ciclo `plan -> implement -> validate/fix -> fresh-session self-review -> close`;
- modo seguro por defecto, sin invocar al proveedor;
- ejecución real sólo con `-Apply`;
- timeout, reintentos, límite de invocaciones y presupuesto estimado;
- pruebas determinísticas con proveedor local simulado;
- evidencia JSON por tarea en `.unique-ai/runs/<task-id>/`.

## Uso rápido

```powershell
.\scripts\unique-ai.ps1 doctor
.\scripts\unique-ai.ps1 plan -TaskId demo -Title "Demo" -Goal "Preparar un plan"
.\scripts\unique-ai.ps1 run -TaskId demo-full -Title "Demo" -Goal "Recorrer todo el ciclo"
.\scripts\test.ps1
```

Los comandos anteriores son dry-run. Una ejecución real requiere `-Apply` y una configuración válida en `.unique-ai/config.json`.

## Límites honestos

- El aislamiento de revisión es por proceso y contexto nuevo del mismo proveedor; no es independencia organizacional.
- El presupuesto es preventivo y estimado por invocación. El adaptador no conoce la facturación real del proveedor.
- No hay merge, push, despliegue ni cambios de producción automáticos.
- La copia local no tiene remoto configurado.
- Antes de usar `-Apply` en un repositorio real debe definirse un contrato y alcance específicos.

Véase [guía operativa](docs/unique-ai/README.md), [arquitectura](docs/unique-ai/architecture.md) y [hitos](docs/unique-ai/milestones.md).
