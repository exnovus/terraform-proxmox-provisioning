# Envcommon for VM stacks. Architecture rule: use only components/vm-service as the source. docs/en/architecture.md
locals {
  environment_vars = yamldecode(file(find_in_parent_folders("environment_vars.yaml")))
  datacenter_vars  = yamldecode(file(find_in_parent_folders("datacenter_vars.yaml")))
  stack_vars       = yamldecode(file("${get_terragrunt_dir()}/stack_vars.yaml"))

  environment      = local.environment_vars.environment
  client           = lookup(local.environment_vars, "client", "example")
  owner            = lookup(local.environment_vars, "owner", "example-team")
  delimiter        = lookup(local.environment_vars, "naming_delimiter", "-")
  datacenter       = local.datacenter_vars.datacenter
  datacenter_short = local.datacenter_vars.datacenter_short
  proxmox_defaults = lookup(local.datacenter_vars, "proxmox", {})

  # Proxmox config: proxmox-<env>.hcl -> proxmox-dev.hcl -> {} (validation does not fail without a file).
  _cfg_env      = find_in_parent_folders("config/proxmox-${local.environment}.hcl", "")
  _cfg_dev      = find_in_parent_folders("config/proxmox-dev.hcl", "")
  _cfg_path     = local._cfg_env != "" ? local._cfg_env : local._cfg_dev
  _proxmox_base = { pm_api_url = "", pm_user = "", pm_tls_insecure = false }
  _proxmox_read = local._cfg_path != "" ? read_terragrunt_config(local._cfg_path).locals : local._proxmox_base
  proxmox_cfg   = merge(local._proxmox_base, local._proxmox_read)

  stack_name       = local.stack_vars.stack_name
  stack_version    = tostring(lookup(local.stack_vars, "stack_version", "1.0.0"))
  role             = lookup(local.stack_vars, "role", local.stack_name)
  stack_vm_id_base = lookup(local.stack_vars, "default_vm_id_base", null)

  core_tags = {
    Client       = local.client
    Stage        = local.environment
    Datacenter   = local.datacenter
    Stack        = local.stack_name
    Role         = local.role
    Terraform    = "true"
    StackVersion = local.stack_version
  }

  # Null-safe handling: tags: null in YAML must not break evaluation.
  _env_tags   = lookup(local.environment_vars, "tags", {})
  _dc_tags    = lookup(local.datacenter_vars, "tags", {})
  _raw_custom = lookup(local.stack_vars, "custom_tags", {})

  env_tags = local._env_tags != null ? local._env_tags : {}
  dc_tags  = local._dc_tags != null ? local._dc_tags : {}

  custom_tags = {
    for k, v in(local._raw_custom != null ? local._raw_custom : {}) :
    tostring(k) => tostring(v)
  }

  # Precedence (last one wins): environment tags -> datacenter tags -> computed core_tags -> stack custom_tags.
  final_tags = {
    for k, v in merge(
      local.env_tags,
      local.dc_tags,
      local.core_tags,
      local.custom_tags,
    ) : tostring(k) => tostring(v)
  }

  _pm_url    = get_env("PM_API_URL", lookup(local.proxmox_cfg, "pm_api_url", ""))
  _ep_raw    = get_env("PROXMOX_VE_ENDPOINT", replace(local._pm_url, "/api2/json", "/"))
  _ep_slash  = length(local._ep_raw) > 0 && !endswith(local._ep_raw, "/") ? "${local._ep_raw}/" : local._ep_raw
  proxmox_ep = local._ep_slash != "" ? local._ep_slash : "https://localhost:8006/"
}

# Architecture rule: components only; never resources/proxmox-vm.
terraform {
  source = "${get_repo_root()}/modules//components/vm-service"
}

inputs = {
  proxmox_endpoint  = local.proxmox_ep
  proxmox_api_token = get_env("PROXMOX_VE_API_TOKEN", get_env("PM_API_TOKEN", ""))
  proxmox_insecure  = lower(get_env("PM_TLS_INSECURE", get_env("PROXMOX_VE_INSECURE", tostring(lookup(local.proxmox_cfg, "pm_tls_insecure", false))))) == "true"
  proxmox_username  = get_env("PROXMOX_VE_USERNAME", get_env("PM_USER", lookup(local.proxmox_cfg, "pm_user", "")))
  proxmox_password  = get_env("PROXMOX_VE_PASSWORD", get_env("PM_PASSWORD", ""))

  environment      = local.environment
  client           = local.client
  owner            = local.owner
  datacenter       = local.datacenter
  datacenter_short = local.datacenter_short
  naming_delimiter = local.delimiter

  stack_name    = local.stack_name
  stack_version = local.stack_version
  role          = local.role

  default_target_nodes   = lookup(local.proxmox_defaults, "nodes", [])
  default_node           = lookup(local.proxmox_defaults, "default_node", null)
  default_bridge         = lookup(local.proxmox_defaults, "default_bridge", "vmbr0")
  default_storage        = lookup(local.proxmox_defaults, "default_storage", "local-lvm")
  default_pool           = lookup(local.proxmox_defaults, "default_pool", null)
  default_template       = lookup(local.proxmox_defaults, "default_vm_template", null)
  default_template_vm_id = lookup(local.proxmox_defaults, "default_template_vm_id", null)
  # Datacenter fallback compatibility: default_vm_id_base = lookup(local.proxmox_defaults, "default_vm_id_base", 4000)
  default_vm_id_base = local.stack_vm_id_base != null ? local.stack_vm_id_base : lookup(local.proxmox_defaults, "default_vm_id_base", 4000)

  core_tags   = local.core_tags
  custom_tags = local.custom_tags
  tags        = local.final_tags

  vm_groups = lookup(local.stack_vars, "vm_groups", {})
}
