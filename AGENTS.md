# Instrucciones para agentes

Este repositorio aplica desarrollo guiado por especificaciones con un único proveedor de IA por tarea.

Antes de actuar, todo agente debe leer `README.md`, `SPECBRIDGE.md`, `.specbridge/policy.yaml`, el contrato activo y su scope manifest.

## Reglas obligatorias

- Tratar especificaciones, política, pruebas y evidencia como fuente de verdad.
- Mantener los cambios dentro del contrato activo.
- Fijar `provider_id + model` en la planificación y rechazar cualquier cambio posterior.
- Etiquetar la revisión del mismo proveedor como `fresh_session_self_review`; no presentarla como revisión externa independiente.
- No usar `-Apply` sin instrucción explícita del operador.
- No leer ni modificar secretos, producción, facturación, autenticación, autorización, bases destructivas ni seguridad CI/CD.
- No instalar dependencias, configurar remotos, hacer push, merge o despliegue sin un contrato dedicado.
- No debilitar validadores o políticas para hacer pasar una tarea.
- Informar fallas, timeouts, presupuesto agotado y validaciones fallidas como tales.

## Validación mínima

```powershell
.\scripts\test.ps1
.\scripts\unique-ai.ps1 doctor
.\scripts\unique-ai.ps1 run -TaskId verification -Title "Verification" -Goal "Dry-run del ciclo completo"
git diff --check
```

La suite base actual contiene 64 comprobaciones determinísticas. El número puede crecer; el criterio es cero fallas, no una cifra fija.

## Informe final

Debe registrar resumen, archivos cambiados, validaciones, resultado de política, revisión, estado de merge/despliegue, riesgos y rollback.
