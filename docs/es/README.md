[English](../en/README.md) | Español

> La documentación en inglés es la fuente de verdad. Las traducciones al español pueden quedar levemente desfasadas.

# Documentación

Documentación técnica pública del repositorio, enfocada en arquitectura, contratos, scaffold, validación y operación segura.

| Documento | Propósito |
|-----------|-----------|
| [primeros-pasos.md](primeros-pasos.md) | Ruta oficial de onboarding para preparar configuración, crear el árbol del proyecto y desplegar los primeros stacks VM y CT |
| [arquitectura.md](arquitectura.md) | Capas de ejecución, regla de arquitectura, herencia, tags y flujo de ejecución |
| [estructura-del-repositorio.md](estructura-del-repositorio.md) | Forma pública del repositorio y responsabilidades por área |
| [configuracion.md](configuracion.md) | Contratos YAML, resolución de configuración Proxmox, backend y estado |
| [scripts-y-scaffold.md](scripts-y-scaffold.md) | Scripts de scaffold, origen de defaults y flujo de bootstrap |
| [guardrails-y-validacion.md](guardrails-y-validacion.md) | Flujo seguro de `plan`/`apply`, cobertura de CI y checks locales |
| [operacion.md](operacion.md) | Runbook público, validación post-apply, recuperación y migración |
| [troubleshooting.md](troubleshooting.md) | Errores frecuentes y diagnóstico rápido |
| [seguridad.md](seguridad.md) | Qué no se debe versionar y checklist de seguridad pre-PR |
| [glosario.md](glosario.md) | Terminología del repositorio |

Referencias adicionales:

- Resumen raíz en inglés: [../../README.md](../../README.md)
- Resumen raíz en español: [../../README.es.md](../../README.es.md)
- Documentación de interfaz de módulos Terraform: `modules/**/README.md`
- Ejemplos públicos: `live/example/`
- Documento recomendado para empezar: [primeros-pasos.md](primeros-pasos.md)
