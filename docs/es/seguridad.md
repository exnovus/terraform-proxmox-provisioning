[English](../en/security.md) | Español | [Índice](README.md)

# Seguridad

## Qué no debe versionarse

- archivos de state: `terraform.tfstate`, `terraform.tfstate.*`
- directorios de state local por stack como `*/state/`
- runtime local dentro de `live/`: `.terraform/`, `.terragrunt-cache/`, `.terraform.lock.hcl`, `terraform.tfstate*`, `tfplan*`, crash logs
- credenciales: `PROXMOX_VE_API_TOKEN`, `PM_API_TOKEN`, `PROXMOX_VE_PASSWORD`, `PM_PASSWORD`, credenciales AWS y cualquier otro secreto
- archivos locales de secrets: `.env`, `.envrc`
- fixtures y artefactos regenerados: `live/_envcommon/`, `live/sre-check/`, `live/ci-test/`

## Qué sí es seguro versionar

- `templates/envcommon/*` como fuente de verdad HCL compartida
- scaffold declarativo bajo `live/<env>/...` cuando represente un ejemplo público limpio o un entorno versionado intencionalmente sin secretos
- config no sensible como `config/proxmox-<env>.hcl` y `config/backend-<env>.hcl`
- módulos y scripts, salvo artefactos generados ya ignorados

## Patrones permitidos

- usar variables de entorno para secretos en runtime
- usar stores de secretos del CI para automatización
- usar `.envrc` local solo si permanece sin versionar
- usar `direnv` con un `.envrc` local solo como comodidad de estación de trabajo, nunca como archivo versionado del proyecto

## Anti-patterns

- guardar contraseñas o tokens en YAML o HCL
- guardar contraseñas o tokens en un `.envrc` versionado
- commitear state o planes binarios
- desactivar verificación TLS en producción sin una justificación documentada
- publicar salidas completas de `terragrunt render --json` cuando puedan incluir inputs sensibles

## Checklist antes de abrir un PR

1. Ejecutar `./scripts/checks_sre.sh` o al menos `./scripts/checks_sre.sh --fast`
2. Confirmar que Terragrunt no referencia `modules/resources/*` de forma directa
3. Confirmar que no se introdujo nueva lógica `generate "tags"` en templates o live
4. Revisar que los archivos tocados no incluyan secretos ni datos sensibles
5. Ejecutar `bash scripts/audit_state.sh` para comprobar que no haya estados fuera de lugar

## Reporte de vulnerabilidades

Si detectas un secreto expuesto, repórtalo de forma privada y rota de inmediato la credencial afectada. No abras un issue público con detalles sensibles.
