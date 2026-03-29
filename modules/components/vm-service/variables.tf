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
  description = "Raw tags from Terragrunt (final_tags). Sanitized by terraform-tags before passing to workload."
  default     = {}
}

variable "core_tags" {
  type        = map(string)
  description = "Deprecated: accepted for compat, not used. Tags are merged in Terragrunt."
  default     = {}
}

variable "custom_tags" {
  type        = map(string)
  description = "Deprecated: accepted for compat, not used. Tags are merged in Terragrunt."
  default     = {}
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

variable "default_pool" {
  type        = string
  description = "Default Proxmox pool"
  default     = null
}

variable "default_template" {
  type        = string
  description = "Default cloud-init VM template"
  default     = null
}

variable "default_template_vm_id" {
  type        = number
  description = "Default template VMID used when VM groups enable clone mode"
  default     = null
}

variable "default_vm_id_base" {
  type        = number
  description = "Base VMID used to derive unique VM IDs (vm_id = base + ordinal). Avoid collisions across stacks."
  default     = 4000
}

variable "default_cloud_init_set_hostname" {
  type        = bool
  description = "Publish local-hostname via cloud-init metadata for cloned VMs when the group does not override it."
  default     = false
}

variable "default_cloud_init_snippets_storage" {
  type        = string
  description = "Proxmox storage with snippets support used for custom cloud-init metadata."
  default     = "local"
}

variable "default_os_template" {
  type        = string
  description = "Unused in VM stack; accepted for shared contract"
  default     = null
}

variable "ct_groups" {
  type        = map(any)
  description = "Unused in VM stack; accepted for shared contract"
  default     = {}
}

variable "vm_groups" {
  description = "Map of VM groups to expand into individual VMs"
  type = map(object({
    enabled                 = optional(bool, true)
    role                    = string
    count                   = number
    cpu                     = number
    ram_mb                  = number
    disk_gb                 = number
    template                = optional(string)
    template_vm_id          = optional(number)
    use_clone               = optional(bool, false)
    target_nodes            = optional(list(string), [])
    node                    = optional(string)
    bridge                  = optional(string)
    storage                 = optional(string)
    pool                    = optional(string)
    agent_enabled           = optional(bool)
    wait_for_agent          = optional(bool)
    agent_timeout           = optional(string)
    cloud_init_set_hostname = optional(bool)
    tags                    = optional(map(string), {})
    custom_tags             = optional(map(string), {})
    extra_disks = optional(list(object({
      interface    = string
      datastore_id = optional(string)
      size_gb      = number
      iothread     = optional(bool)
      discard      = optional(string)
      ssd          = optional(bool)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for group in values(var.vm_groups) : [
        for disk in try(group.extra_disks, []) :
        can(regex("^scsi[0-9]+$", lower(trimspace(disk.interface))))
      ]
    ]))
    error_message = "vm_groups[*].extra_disks[*].interface must match scsiN (for example scsi1 or scsi2)."
  }

  validation {
    condition = alltrue(flatten([
      for group in values(var.vm_groups) : [
        for disk in try(group.extra_disks, []) :
        lower(trimspace(disk.interface)) != "scsi0"
      ]
    ]))
    error_message = "vm_groups[*].extra_disks[*].interface cannot be scsi0 because that interface is reserved for the OS disk."
  }

  validation {
    condition = alltrue([
      for group in values(var.vm_groups) :
      length(distinct([for disk in try(group.extra_disks, []) : lower(trimspace(disk.interface))])) == length(try(group.extra_disks, []))
    ])
    error_message = "Each vm_groups entry must define unique extra_disks interfaces per VM."
  }

  validation {
    condition = alltrue(flatten([
      for group in values(var.vm_groups) : [
        for disk in try(group.extra_disks, []) :
        disk.size_gb > 0
      ]
    ]))
    error_message = "vm_groups[*].extra_disks[*].size_gb must be greater than 0."
  }
}
