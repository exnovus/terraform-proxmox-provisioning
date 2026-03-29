# VM component: the single entrypoint for VM stacks. Orchestrates tags-manager
# and the workload; Terragrunt must only invoke this module (never resources/proxmox-vm directly).
module "terraform_tags" {
  source    = "../../core/tags-manager"
  name      = var.stack_name
  stage     = var.environment
  client    = var.client
  delimiter = var.naming_delimiter
  tags      = var.tags
}

# The workload module receives already-sanitized tags; it adds role/group/index and builds a taglist per VM.
module "workload" {
  source = "../../resources/proxmox-vm"

  client           = var.client
  environment      = var.environment
  owner            = var.owner
  datacenter       = var.datacenter
  datacenter_short = var.datacenter_short
  stack_name       = var.stack_name
  stack_version    = var.stack_version
  role             = var.role
  naming_delimiter = var.naming_delimiter

  tags = module.terraform_tags.tags_sanitized

  default_target_nodes                = var.default_target_nodes
  default_node                        = var.default_node
  default_bridge                      = var.default_bridge
  default_storage                     = var.default_storage
  default_pool                        = var.default_pool
  default_template                    = var.default_template
  default_template_vm_id              = var.default_template_vm_id
  default_vm_id_base                  = var.default_vm_id_base
  default_cloud_init_set_hostname     = var.default_cloud_init_set_hostname
  default_cloud_init_snippets_storage = var.default_cloud_init_snippets_storage

  vm_groups = var.vm_groups
}
