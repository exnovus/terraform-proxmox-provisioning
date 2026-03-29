variable "client" {
  type        = string
  description = "Client code used in resource names"
}

variable "environment" {
  type        = string
  description = "Environment code used in resource names"
}

variable "owner" {
  type        = string
  description = "Owner for this stack"
  default     = ""
}

variable "datacenter" {
  type        = string
  description = "Datacenter full name"
  default     = ""
}

variable "datacenter_short" {
  type        = string
  description = "Datacenter short code used in resource names"
}

variable "stack_name" {
  type        = string
  description = "Stack name"
  default     = ""
}

variable "stack_version" {
  type        = string
  description = "Stack version"
  default     = "1.0.0"
}

variable "role" {
  type        = string
  description = "Default stack role"
  default     = ""
}

variable "naming_delimiter" {
  type        = string
  description = "Delimiter used in naming"
  default     = "-"
}

variable "tags" {
  type        = map(string)
  description = "Final tags map from Terragrunt stack layer"
  default     = {}
  nullable    = false
}

variable "core_tags" {
  type        = map(string)
  description = "Deprecated: kept for backward compat. Use tags."
  default     = {}
  nullable    = false
}

variable "custom_tags" {
  type        = map(string)
  description = "Deprecated: kept for backward compat. Use tags."
  default     = {}
  nullable    = false
}

variable "default_target_nodes" {
  type        = list(string)
  description = "Default target node rotation list"
  default     = []
}

variable "default_node" {
  type        = string
  description = "Fallback node when no target_nodes are provided"
  default     = null
}

variable "default_bridge" {
  type        = string
  description = "Default network bridge"
  default     = "vmbr0"
}

variable "default_storage" {
  type        = string
  description = "Default storage backend"
  default     = "local-lvm"
}

variable "default_ct_id_base" {
  type        = number
  description = "Base CT ID used to derive unique container IDs"
  default     = 200
}

variable "default_pool" {
  type        = string
  description = "Default Proxmox pool"
  default     = null
}

variable "default_os_template" {
  type        = string
  description = "Default LXC OS template"
  default     = null
}

variable "default_template" {
  type        = string
  description = "Unused in CT module; accepted for shared stack contract"
  default     = null
}

variable "vm_groups" {
  type        = map(any)
  description = "Unused in this module; kept to allow unified stack inputs"
  default     = {}
}

variable "ct_groups" {
  description = "Map of CT groups to expand into individual containers"
  type = map(object({
    enabled      = optional(bool, true)
    role         = string
    count        = number
    cpu          = number
    ram_mb       = number
    disk_gb      = number
    os_template  = optional(string)
    target_nodes = optional(list(string), [])
    node         = optional(string)
    bridge       = optional(string)
    storage      = optional(string)
    pool         = optional(string)
    unprivileged = optional(bool, true)
    onboot       = optional(bool, true)
    start        = optional(bool, true)
    ipv4         = optional(string, "dhcp")
    ipv4_gateway = optional(string)
    tags         = optional(map(string), {})
    custom_tags  = optional(map(string), {})
  }))
  default = {}
}
