# ------------------------------------------------------------------------------
# providers.hcl — Generates providers.tf with bpg/proxmox (actively maintained).
# Authentication: api_token (recommended) or username+password. Do not commit secrets.
# See: https://github.com/bpg/terraform-provider-proxmox
# ------------------------------------------------------------------------------
locals {
  terraform_version = trimspace(file(find_in_parent_folders(".terraform-version")))
}

generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOT
    terraform {
      required_version = "= ${local.terraform_version}"

      required_providers {
        proxmox = {
          source  = "bpg/proxmox"
          version = "~> 0.98"
        }
      }
    }

    # Connection variables: filled by _envcommon from config + get_env.
    variable "proxmox_endpoint" {
      type        = string
      description = "Proxmox API endpoint (e.g. https://host:8006/)"
    }

    variable "proxmox_api_token" {
      type        = string
      description = "API token (user@realm!tokenid=uuid), or empty when username/password authentication is used"
      default     = ""
      sensitive   = true
    }

    variable "proxmox_insecure" {
      type        = bool
      description = "Disable TLS verification"
      default     = false
    }

    # Optional: username/password authentication (when api_token is empty)
    variable "proxmox_username" {
      type        = string
      description = "Proxmox username (for example <user@realm>) when api_token is not used"
      default     = ""
    }

    variable "proxmox_password" {
      type        = string
      description = "Proxmox password when api_token is not used"
      default     = ""
      sensitive   = true
    }

    provider "proxmox" {
      endpoint  = var.proxmox_endpoint
      insecure  = var.proxmox_insecure
      api_token = var.proxmox_api_token != "" ? var.proxmox_api_token : null
      username  = var.proxmox_username != "" ? var.proxmox_username : null
      password  = var.proxmox_password != "" ? var.proxmox_password : null
    }
  EOT
}
