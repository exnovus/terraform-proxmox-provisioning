# --- Existing outputs (preserved for backward compatibility) ---

output "id" {
  description = "Full normalized id"
  value       = local.id
}

output "name" {
  description = "Original name input"
  value       = var.name
}

output "stage" {
  description = "Original stage input"
  value       = var.stage
}

output "client" {
  description = "Original client input"
  value       = var.client
}

output "tags" {
  description = "All tags including Name (original format, not sanitized)"
  value       = local.final_tags
}

output "tags_no_name" {
  description = "All tags excluding Name"
  value = {
    for k, v in local.final_tags : k => v
    if lower(k) != "name"
  }
}

# --- New outputs (Proxmox extension) ---

output "tags_sanitized" {
  description = "Sanitized tags map for Proxmox: lowercase keys/values, only [a-z0-9_.:-] chars"
  value       = local.tags_sanitized
}

output "taglist" {
  description = "Proxmox taglist string: key-value pairs sorted, distinct, joined by ;"
  value       = local.taglist
}
