# tags-manager: a single source of truth for tags. Normalizes to string, sanitizes
# keys/values to the format accepted by Proxmox ([a-z0-9_.:-] characters), and exposes
# tags_sanitized + taglist for the provider.
locals {
  id = lower(join(var.delimiter, compact([
    var.client,
    var.stage,
    var.name,
  ])))

  core_tags = {
    Name   = local.id
    Client = var.client
    Stage  = var.stage
  }

  final_tags = merge(local.core_tags, var.tags)

  # Regex for Proxmox: replace any unsupported character with _.
  sanitize_re = "/[^a-z0-9_.:-]/"

  tags_string = {
    for k, v in var.tags : tostring(k) => tostring(v)
  }

  tags_sanitized = {
    for k, v in local.tags_string :
    replace(lower(k), local.sanitize_re, "_") =>
    replace(lower(tostring(v)), local.sanitize_re, "_")
  }

  tagpairs = [
    for k, v in local.tags_sanitized : "${k}-${v}"
  ]

  taglist = join(";", sort(distinct(local.tagpairs)))
}
