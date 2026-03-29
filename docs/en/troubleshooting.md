English | [Español](../es/troubleshooting.md) | [Docs index](README.md)

# Troubleshooting

## Common errors

| Problem | Likely cause | Action |
|--------|--------------|--------|
| `401 authentication failure` | Proxmox credentials are wrong or not exported | Check `PROXMOX_VE_ENDPOINT` or `PM_API_URL`, and either token variables or username/password variables |
| Module not found or wrong module path | Terragrunt is not pointing to the component module | `_envcommon/*.hcl` must use `modules//components/vm-service` or `modules//components/lxc-service` |
| Proxmox provider not found | Wrong provider or not initialized | Use `bpg/proxmox` from `providers.hcl` and run `terragrunt init -upgrade` |
| `Invalid resource type proxmox_virtual_environment_vm` or `...container` | Provider and module contract are out of sync | Verify `providers.hcl` and `modules/resources/*/versions.tf` both use `bpg/proxmox` |
| `init` asks for input | Backend or provider needs initialization or reconfiguration | Run `terragrunt init`, or `terragrunt init -reconfigure` when backend settings changed |
| Missing envcommon file | `live/_envcommon/` was deleted or is incomplete | Recreate it with `./scripts/create_environment.sh <env> --force` |
| Backend changed, init required | Effective backend config differs from the local initialization | Run `terragrunt init -reconfigure`, or `-migrate-state` if migrating real state |
| `Error acquiring the state lock` | Another process holds the lock | Confirm no other run is active; if safe, use `terragrunt force-unlock <LOCK_ID>` |
| `error asking for approval: EOF` | Interactive apply without TTY or without a saved plan | Run `terragrunt plan -out=tfplan` first, then `terragrunt apply tfplan` |
| VM clone fails or template VM not found | `default_vm_template`, `default_template_vm_id`, or `template_vm_id` does not match a real Proxmox template | Check `datacenter_vars.yaml` and `stack_vars.yaml` |
| `expected template_file_id to be a valid file identifier` | CT stack uses an incomplete `os_template` value | Use the full identifier form `datastore:vztmpl/file.tar.zst` |
| `volume '<template>' does not exist` | The configured LXC template is not uploaded in Proxmox | Verify the actual template file in Proxmox and update the contract |
| Storage, pool, or node not found | Public defaults do not match the current cluster | Adjust `config/datacenter-defaults.yaml` or `datacenter_vars.yaml` |
| No IP appears in `terragrunt output` | VM outputs expose metadata, not guest IPs | Query the IP through Proxmox UI or the guest-agent API |
| VM is created but no IP appears in Proxmox | The template lacks `qemu-guest-agent`, the service is down, or `agent_enabled` is `false` | Validate the template, the guest service, and `agent_enabled` |
| `Warning: error waiting for network interfaces from QEMU agent` | The provider queried the guest before the agent published the interfaces | Review `agent_enabled`, `wait_for_agent`, and `agent_timeout`; verify the guest agent inside the VM |
| VM reports the template hostname through DHCP | Cloud-init metadata was not applied or snippets storage is unavailable | Verify `cloud_init_set_hostname`, `meta_data_file_id`, snippets storage support, and guest cloud-init status |
| Cloud-init metadata upload fails or Proxmox rejects the snippet | The snippets storage does not support `snippets` or is not available on the target node | Confirm storage capabilities and node visibility in Proxmox |
| Plan shows VM replacement when cloud-init metadata is attached | The provider treats `meta_data_file_id` as part of the VM definition | Plan a controlled recreation and validate the hostname after apply |
| SSH fails with the expected user | The cloud-init template uses a different guest user | Check the template customization and connect with the actual configured user |

## Quick validation

From a stack:

```bash
terragrunt init -upgrade
terragrunt validate
terragrunt plan
```

If `validate` fails, inspect HCL/Terraform syntax and the files resolved by `find_in_parent_folders()`. If `plan` fails with `401`, review the Proxmox environment variables first.
