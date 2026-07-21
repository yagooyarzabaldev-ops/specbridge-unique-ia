# Arquitectura

```text
objetivo + contrato + scope
          |
          v
 scripts/unique-ai.ps1
          |
          +--> plan ----------- proveedor A / modelo M
          +--> implement ------ proveedor A / modelo M
          +--> validate ------- scripts determinísticos
          |       \-> fix ----- proveedor A / modelo M, sólo si falla
          +--> review --------- proveedor A / modelo M, proceso nuevo
          +--> close ---------- puerta determinística
```

## Componentes

- `unique-ai-common.ps1`: JSON UTF-8 sin BOM, rutas, artefactos y resultados.
- `unique-ai-provider.ps1`: validación de configuración, identidad, proceso, timeout, reintentos y presupuesto.
- `unique-ai-lifecycle.ps1`: orden de fases y prerequisitos.
- `.unique-ai/config.json`: proveedor activo y límites.
- `.unique-ai/runs/<task-id>`: plan, resultados de fase y consumo estimado.
- `tests/unique-ai`: pruebas determinísticas y proveedor simulado.

## Identidad e independencia

`plan.json` fija `provider_id` y `model`. Implementación, corrección y revisión comparan ambos valores antes de ejecutar. La revisión abre otro proceso y genera `session_id`; esto reduce contaminación de contexto, pero no equivale a una revisión de otra organización o modelo.

## Presupuesto

El núcleo no interpreta facturas del proveedor. Antes de cada intento comprueba:

- `max_invocations`;
- `budget_usd` frente a `estimated_cost_per_invocation_usd`;
- `max_retries`;
- `timeout_seconds`.

`usage.json` conserva el contador por tarea. Es un límite preventivo, no contabilidad financiera exacta.

## Limitaciones del MVP

- La salida libre del proveedor no se valida aún contra un esquema semántico de plan o revisión.
- Un proceso que produzca volúmenes extremos de stdout/stderr puede requerir streaming en una versión futura.
- El aislamiento depende de que los argumentos configurados no reanuden una sesión anterior.
- La política de archivos limita validaciones y gobernanza, pero el CLI proveedor conserva las capacidades que le otorgue su entorno; debe ejecutarse en sandbox apropiado.
- No existe todavía publicación remota ni empaquetado instalable.
