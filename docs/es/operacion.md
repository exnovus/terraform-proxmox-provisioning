[English](../en/operations.md) | Español | [Índice](README.md)

# Operación

Este es el runbook público para bootstrap de entornos, validación de stacks, rotación de credenciales y recuperación de situaciones comunes a nivel de repositorio.

## Bootstrap de un entorno nuevo

1. Revisar los defaults del scaffold antes de generar el datacenter:

   ```bash
   sed -n '1,120p' config/datacenter-defaults.yaml
   ```

   Los archivos públicos bajo `live/example/` sirven como referencia del contrato YAML y de las convenciones de naming.

2. Crear el environment y el datacenter:

   ```bash
   ./scripts/create_environment.sh demo
   ./scripts/create_environment_datacenter.sh demo lab-01
   ```

3. Crear uno o más stacks:

   ```bash
   ./scripts/create_environment_stack.sh demo lab-01 vm-demo vm
   ```

4. Revisar el YAML generado antes del primer plan:

   - ajustar nodos, bridge, storage y pool al cluster real
   - confirmar el nombre del template VM y el VMID del template
   - para stacks CT, asegurar que exista un `os_template` real en `datacenter_vars.yaml` o en `stack_vars.yaml`

5. Exportar acceso local a Proxmox. Se recomienda autenticación por token:

   ```bash
   export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
   export PROXMOX_VE_API_TOKEN="<token>"
   export PROXMOX_VE_INSECURE="true"
   ```

   También se soporta modo usuario/contraseña:

   ```bash
   export PM_API_URL="https://<host>:8006/api2/json"
   export PM_USER="<user@realm>"
   export PM_PASSWORD="<secreto>"
   export PM_TLS_INSECURE="true"
   ```

   `direnv` es una alternativa local práctica para estas variables. Puedes crear un `.envrc` no versionado en lugar de repetir `export` manualmente.

6. Inicializar, validar, planificar y aplicar desde el stack:

   ```bash
   cd live/demo/lab-01/vm-demo
   terragrunt init -upgrade
   terragrunt validate
   terragrunt plan -out=tfplan
   terragrunt apply tfplan
   ```

7. Auditar el layout de state resultante:

   ```bash
   bash scripts/audit_state.sh
   ```

## Flujo local opcional con direnv

Instala `direnv`:

- macOS con Homebrew: `brew install direnv`
- Linux con el gestor de paquetes del sistema, por ejemplo:
  - Debian o Ubuntu: `sudo apt-get install direnv`
  - Fedora: `sudo dnf install direnv`
  - Arch Linux: `sudo pacman -S direnv`

Activa el hook del shell:

- Bash: `echo 'eval "$(direnv hook bash)"' >> ~/.bashrc`
- Zsh: `echo 'eval "$(direnv hook zsh)"' >> ~/.zshrc`

Crea un `.envrc` local en la raíz del repositorio:

```bash
export PROXMOX_VE_ENDPOINT="https://<host>:8006/"
export PROXMOX_VE_API_TOKEN="<token>"
export PROXMOX_VE_INSECURE="true"

# Credenciales opcionales para backend remoto
# export AWS_ACCESS_KEY_ID="<access-key>"
# export AWS_SECRET_ACCESS_KEY="<secret-key>"
```

Si prefieres autenticación por usuario/contraseña, exporta en su lugar `PM_API_URL`, `PM_USER`, `PM_PASSWORD` y `PM_TLS_INSECURE`.

Autorízalo en local:

```bash
direnv allow
```

Después de editar `.envrc`, recárgalo:

```bash
direnv reload
```

El repositorio ignora tanto `.envrc` como `.direnv/`. Deben mantenerse locales y revisarse con el mismo cuidado que cualquier archivo con secretos.

## Validación post-apply en VMs

El mapa de instancias VM usa la clave `<group>-NN`. El scaffold genérico y el ejemplo público VM usan `primary-01`.

1. Inspeccionar metadata de la VM vía outputs de Terragrunt:

   ```bash
   cd live/demo/lab-01/vm-demo
   terragrunt output -json | jq '.vm_instances.value."primary-01" | {vm_id, vm_name, target_node, cloning, agent_enabled, wait_for_agent, cloud_init_set_hostname}'
   ```

2. Confirmar en Proxmox que la VM existe y está en ejecución:

- UI: `Datacenter -> <node> -> <vmid> -> Summary`
- API: `GET /nodes/<node>/qemu/<vmid>/status/current`

3. Si `cloud_init_set_hostname: true` está habilitado, Proxmox adjunta metadata cloud-init para que el guest adopte el nombre lógico definido por Terraform.

4. Si el template incluye `qemu-guest-agent` y `agent_enabled: true`, Proxmox puede exponer interfaces del guest vía agent. `wait_for_agent` controla si Terraform espera esa señal.

5. Consultar interfaces de red desde Proxmox si hace falta:

- UI: `Datacenter -> <node> -> <vmid> -> Summary`
- API: `GET /nodes/<node>/qemu/<vmid>/agent/network-get-interfaces`

6. Validar reachability e identidad del guest:

   ```bash
   timeout 5 bash -lc '</dev/tcp/<ip>/22' && echo ssh-port-open
   ssh <cloud-init-user>@<ip>
   hostnamectl --static
   cat /etc/hostname
   ```

7. Destruir el stack cuando termine la ventana de validación:

   ```bash
   terragrunt destroy -auto-approve
   ```

## Requisitos operativos para CT

- el storage seleccionado para CT debe soportar `rootdir`
- el template LXC debe existir en Proxmox y usar el identificador completo
- `config/datacenter-defaults.yaml` mantiene `default_ct_template: null`
- el archivo público de ejemplo para datacenter fija un template Debian explícito para que el ejemplo CT sea autocontenido
- si el cluster usa nodos, storage o pools distintos a los defaults públicos, ajustar `config/datacenter-defaults.yaml` o `datacenter_vars.yaml` antes del primer apply

## Rotación de credenciales Proxmox

1. Rotar la credencial en Proxmox según el modo de autenticación en uso
2. Actualizar la variable de entorno correspondiente en local o en CI
3. Ejecutar `terragrunt plan` en un stack para confirmar conectividad

El repositorio no guarda secretos en `config/proxmox-<env>.hcl`. Las credenciales deben venir del entorno de ejecución.

## Rotación de credenciales AWS para backend

1. Rotar access keys en IAM
2. Actualizar `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY` en el entorno o en secretos de CI
3. Ejecutar `terragrunt init` en un stack para confirmar acceso

## Recuperación tras borrar `live/<env>` o `live/_envcommon`

- si solo se borró el árbol de un environment, regenerarlo con los scripts de scaffold
- si falta `live/_envcommon/`, `create_environment.sh <env> --force` lo reconstruye desde `templates/envcommon/`
- si se usaba backend local, borrar `live/<env>/<dc>/<stack>/state/` elimina el state local
- si se usaba backend remoto, el state permanece en S3
- árboles temporales como `live/ci-test/` y `live/sre-check/` se regeneran desde CI o desde comandos locales de validación cuando hace falta

## Migración de state local a remoto

Resumen:

1. crear bucket S3 y tabla DynamoDB
2. completar `config/backend-<env>.hcl`
3. ejecutar `terragrunt init -reconfigure -migrate-state` por stack
4. confirmar con `terragrunt state list`

Ver [configuracion.md](configuracion.md) para el detalle del backend.
