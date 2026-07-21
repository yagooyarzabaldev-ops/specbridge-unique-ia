# Contrato técnico de SpecBridge Unique IA

## Propósito

Convertir un objetivo gobernado en un ciclo de desarrollo ejecutable por una sola IA configurable, sin acoplar el núcleo a Claude, Codex, OpenAI, Anthropic ni otro proveedor particular.

## Invariantes

1. Una tarea fija `provider_id` y `model` en `plan.json`.
2. Ninguna fase posterior puede cambiar esa identidad.
3. Cada llamada al proveedor es un proceso nuevo; la revisión se etiqueta `fresh_session_self_review`.
4. Sin `-Apply` no se inicia ningún proceso de IA.
5. Una falla, timeout o presupuesto agotado produce `ok=false`; nunca se convierte en éxito.
6. `close` en modo real exige implementación, validación y revisión exitosas.
7. Los scripts de validación son rutas `.ps1` declaradas, resueltas dentro del repositorio y filtradas contra rutas bloqueadas.
8. El sistema no ejecuta merge, push ni despliegue.

## Ciclo

```text
plan -> implement -> validate
                       | falla
                       v
                     fix -> validate
                       |
                       v
fresh-session self-review -> close
```

Plan, implementación, corrección y revisión usan el mismo proveedor y modelo. Validación y cierre son puertas determinísticas.

## Adaptador

El proveedor se configura mediante un ejecutable local y una lista de argumentos. El prompt se entrega por `stdin`; no se usa `Invoke-Expression`, evaluación de shell ni SDK de proveedor. Timeout, reintentos e invocaciones se controlan fuera del proveedor.

## Evidencia

Cada fase escribe JSON bajo `.unique-ai/runs/<task-id>/`. `usage.json` registra invocaciones y gasto estimado. Estos artefactos operativos están ignorados por Git por defecto.

## Autoridad

Política, contrato activo, alcance declarado, validaciones y evidencia del repositorio prevalecen sobre la salida del modelo. La IA no puede ampliar por sí sola su alcance.
