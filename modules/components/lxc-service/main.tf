# LXC component: entrypoint for CT stacks. Orchestrates tags-manager and the workload;
# Terragrunt must never point directly to resources/proxmox-lxc.
module "terraform_tags" {
  source    = "../../core/tags-manager"
  name      = var.stack_name
  stage     = var.environment
  client    = var.client
  delimiter = var.naming_delimiter
  tags      = var.tags
}

module "workload" {
  source = "../../resources/proxmox-lxc"

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

  default_target_nodes = var.default_target_nodes
  default_node         = var.default_node
  default_bridge       = var.default_bridge
  default_storage      = var.default_storage
  default_ct_id_base   = var.default_ct_id_base
  default_pool         = var.default_pool
  default_os_template  = var.default_os_template

  ct_groups = var.ct_groups
}
