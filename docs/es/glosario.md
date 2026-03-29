[English](../en/glossary.md) | Español | [Índice](README.md)

# Glosario

| Término | Definición |
|---------|------------|
| Component | Módulo Terraform bajo `modules/components/` que actúa como entrypoint de Terragrunt y orquesta `tags-manager` más el workload |
| Resource workload | Módulo Terraform bajo `modules/resources/` que crea recursos Proxmox y nunca debe ser target directo de Terragrunt |
| tags-manager | Módulo compartido en `modules/core/tags-manager` que normaliza, sanitiza y formatea tags para Proxmox |
| `_envcommon` | HCL compartido bajo `live/_envcommon/`, generado desde `templates/envcommon/`, usado para leer contratos YAML y componer inputs |
| Stack | Unidad desplegable en `live/<env>/<datacenter>/<stack>/` |
| Scaffold | Generación automatizada de la estructura de environment, datacenter y stack |
| Guardrails | Restricciones de ejecución y checks anti-regresión que protegen el contrato público del repo |
| Backend local | State guardado por stack en `state/terraform.tfstate` |
| Backend remoto | Backend compatible con S3 y locking en DynamoDB, habilitado desde `config/backend-<env>.hcl` |
| Auditoría de estado | Revisión ejecutada por `scripts/audit_state.sh` para detectar state canónico, estados fuera de lugar y residuos en caché |
| Regla de arquitectura | Terragrunt solo apunta a `modules/components/*`, nunca a `modules/resources/*` |
| `find_in_parent_folders` | Helper de Terragrunt que busca un archivo subiendo por el árbol de directorios |
| `get_repo_root()` | Helper de Terragrunt que devuelve la raíz del repositorio y se usa para sources absolutos de módulos |
