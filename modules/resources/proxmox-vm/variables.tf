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
  description = "Pre-sanitized base tags map. Passed by the stack wrapper from terraform-tags.tags_sanitized."
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

# ---------------------------------------------------------------------------
# Default Proxmox infrastructure values
# ---------------------------------------------------------------------------

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
  description = "Default storage backend for VM disks"
  default     = "local-lvm"
}

variable "default_pool" {
  type        = string
  description = "Default Proxmox pool"
  default     = null
}

variable "default_template" {
  type        = string
  description = "Default cloud-init VM template name. Informational only; clone mode uses default_template_vm_id."
  default     = null
}

variable "default_template_vm_id" {
  type        = number
  description = "Template VMID in Proxmox for clone mode. Required when use_clone = true."
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
  description = "Unused in VM module; accepted for shared stack contract"
  default     = null
}

# ---------------------------------------------------------------------------
# Default QEMU VM values (machine, CPU, agent, disk, lifecycle)
# ---------------------------------------------------------------------------

variable "default_machine" {
  type        = string
  description = "QEMU machine type. Use 'q35' for modern guests with PCIe passthrough support."
  default     = "q35"
}

variable "default_sockets" {
  type        = number
  description = "Default CPU socket count"
  default     = 1
}

variable "default_cpu_type" {
  type        = string
  description = "Default CPU type. Use 'host' for best performance, 'x86-64-v2-AES' for broad compat."
  default     = "host"
}

variable "default_agent_enabled" {
  type        = bool
  description = "Enable QEMU Guest Agent by default. Requires qemu-guest-agent installed in the guest."
  default     = true
}

variable "default_scsihw" {
  type        = string
  description = "SCSI controller type. Use 'virtio-scsi-single' to enable per-disk iothread."
  default     = "virtio-scsi-single"
}

variable "default_disk_iothread" {
  type        = bool
  description = "Enable IO thread per disk. Only effective when scsihw = virtio-scsi-single."
  default     = true
}

variable "default_start_on_create" {
  type        = bool
  description = "Start the VM immediately after Terraform creates it (maps to provider attribute 'started'). Only applies when use_clone = true; without a template, started remains false."
  default     = true
}

# ---------------------------------------------------------------------------
# QEMU agent (only relevant when use_clone=true and there is a cloud-init template)
# ---------------------------------------------------------------------------

variable "default_wait_for_agent" {
  type        = bool
  description = "Wait for the QEMU Guest Agent to publish interfaces when the agent is enabled and the VM is created from a template. Without a template, this avoids the 15-minute timeout."
  default     = true
}

variable "default_agent_timeout" {
  type        = string
  description = "Guest agent timeout (for example 5m or 120). Applies only when agent_enabled = true, wait_for_agent = true, and the VM is created from a template."
  default     = "5m"
}

variable "default_ssh_pubkey_path" {
  type        = string
  description = "Path to the SSH public key file for cloud-init (optional)."
  default     = null
}

# ---------------------------------------------------------------------------
# Disk (SSD/TRIM for guest systems with an OS)
# ---------------------------------------------------------------------------

variable "default_disk_discard" {
  type        = string
  description = "Discard mode for disks (on=TRIM, unmap, ignore)."
  default     = "on"
}

variable "default_disk_ssd" {
  type        = bool
  description = "Emulate the disk as SSD."
  default     = true
}

# ---------------------------------------------------------------------------
# Unused inputs (shared stack contract)
# ---------------------------------------------------------------------------

variable "ct_groups" {
  type        = map(any)
  description = "Unused in this module; kept to allow unified stack inputs"
  default     = {}
}

# ---------------------------------------------------------------------------
# VM groups
# ---------------------------------------------------------------------------

variable "vm_groups" {
  description = "Map of VM groups to expand into individual VMs"
  type = map(object({
    enabled        = optional(bool, true)
    role           = string
    count          = number
    cpu            = number
    ram_mb         = number
    disk_gb        = number
    template       = optional(string)
    template_vm_id = optional(number)
    use_clone      = optional(bool, false)
    target_nodes   = optional(list(string), [])
    node           = optional(string)
    bridge         = optional(string)
    storage        = optional(string)
    pool           = optional(string)

    machine                 = optional(string)
    sockets                 = optional(number)
    cpu_type                = optional(string)
    agent_enabled           = optional(bool)
    scsihw                  = optional(string)
    disk_iothread           = optional(bool)
    start_on_create         = optional(bool)
    wait_for_agent          = optional(bool)
    agent_timeout           = optional(string)
    cloud_init_set_hostname = optional(bool)
    ssh_pubkey_path         = optional(string)

    tags        = optional(map(string), {})
    custom_tags = optional(map(string), {})
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
