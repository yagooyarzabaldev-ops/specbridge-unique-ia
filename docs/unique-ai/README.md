# Guía operativa

## Configuración

Copie `.unique-ai/example-config.json` a `.unique-ai/config.json` y defina:

- `provider_id`: identidad estable del proveedor;
- `model`: modelo fijo para toda la tarea;
- `executable`: CLI local ya instalada;
- `arguments`: argumentos literales, sin comandos de shell;
- `limits`: reintentos, timeout, presupuesto estimado e invocaciones máximas;
- `validation_scripts`: rutas `.ps1` relativas al repositorio;
- `blocked_paths`: rutas que nunca pueden habilitarse como validaciones.

El prompt se envía por entrada estándar. La configuración no debe contener tokens ni claves.

## Comandos

```powershell
# Diagnóstico; no llama al proveedor
.\scripts\unique-ai.ps1 doctor

# Plan y ciclo completo en dry-run
.\scripts\unique-ai.ps1 plan -TaskId tarea-1 -Title "Título" -Goal "Objetivo"
.\scripts\unique-ai.ps1 run -TaskId tarea-2 -Title "Título" -Goal "Objetivo"

# Ejecución real: requiere autorización explícita y proveedor configurado
.\scripts\unique-ai.ps1 run -TaskId tarea-real -Title "Título" -Goal "Objetivo" -Apply
```

`run` detiene el ciclo ante la primera fase fallida. En modo real, `close` sólo completa si implementación, validación y revisión terminaron correctamente.

## Seguridad

- Dry-run es obligatorio por defecto.
- No se evalúan strings como comandos de shell.
- Las validaciones sólo aceptan scripts `.ps1` declarados, existentes dentro del repositorio y no bloqueados.
- Cada llamada al proveedor inicia un proceso nuevo y tiene timeout.
- Las fallas se reintentan como máximo según `max_retries`.
- El presupuesto se controla con costo estimado por invocación y `max_invocations`.
- No se automatizan Git remoto, merge, despliegue ni producción.

## Verificación

```powershell
.\scripts\test.ps1
.\scripts\unique-ai.ps1 doctor
git diff --check
```

La suite usa un proveedor simulado local. No necesita red ni consume una API.

## Rollback

El código nuevo está aislado en `scripts/unique-ai.ps1`, `scripts/lib/unique-ai-*`, `.unique-ai`, `tests/unique-ai` y `docs/unique-ai`. Para revertir una tarea operativa se puede retirar únicamente su carpeta bajo `.unique-ai/runs/`. Para revertir el producto, restaure la rama o elimine sólo esos archivos mediante un cambio Git revisado.

No hay remoto, despliegue ni migración de datos que deshacer en esta copia.
