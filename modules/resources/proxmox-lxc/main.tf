# LXC workload: creates proxmox_virtual_environment_container resources (bpg/proxmox provider).
# See: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_container
locals {
  sanitize_re = "/[^a-z0-9_.:-]/"

  expanded_ct_instances = flatten([
    for group_name, group in var.ct_groups : [
      for index in range(group.count) : {
        group_name  = group_name
        role        = group.role
        ordinal     = index + 1
        index2      = format("%02d", index + 1)
        cpu         = group.cpu
        ram_mb      = group.ram_mb
        disk_gb     = group.disk_gb
        os_template = coalesce(try(group.os_template, null), var.default_os_template)
        target_node = (
          length(try(group.target_nodes, [])) > 0
          ? group.target_nodes[index % length(group.target_nodes)]
          : coalesce(try(group.node, null), var.default_node, try(var.default_target_nodes[0], null))
        )
        bridge       = coalesce(try(group.bridge, null), var.default_bridge)
        storage      = coalesce(try(group.storage, null), var.default_storage)
        pool         = try(coalesce(try(group.pool, null), var.default_pool), null)
        unprivileged = try(group.unprivileged, true)
        onboot       = try(group.onboot, true)
        start        = try(group.start, true)
        ipv4         = try(group.ipv4, "dhcp")
        ipv4_gateway = try(group.ipv4_gateway, null)
        tags = merge(
          var.tags,
          {
            for k, v in merge(
              coalesce(try(group.tags, null), {}),
              coalesce(try(group.custom_tags, null), {}),
            ) : replace(lower(tostring(k)), local.sanitize_re, "_") =>
            replace(lower(tostring(v)), local.sanitize_re, "_")
            if can(tostring(k)) && v != null && can(tostring(v))
          },
          {
            role          = replace(lower(group.role), local.sanitize_re, "_")
            resource_type = "ct"
            group         = replace(lower(group_name), local.sanitize_re, "_")
            index         = format("%02d", index + 1)
          }
        )
        ct_name = lower(join(var.naming_delimiter, compact([
          var.client,
          var.environment,
          var.datacenter_short,
          group.role,
          format("%02d", index + 1),
        ])))
        enabled = try(group.enabled, true)
      }
    ]
  ])

  # Global ordinal (flatten idx) -> unique vm_id even across multiple groups.
  enabled_ct_instances = {
    for idx, instance in local.expanded_ct_instances :
    "${instance.group_name}-${instance.index2}" => merge(instance, {
      vm_id     = var.default_ct_id_base + idx + 1
      tags_list = sort([for k, v in instance.tags : "${k}-${v}"])
    })
    if instance.enabled
  }
}

resource "proxmox_virtual_environment_container" "ct" {
  for_each = local.enabled_ct_instances

  node_name = each.value.target_node
  vm_id     = each.value.vm_id

  unprivileged  = each.value.unprivileged
  started       = each.value.start
  start_on_boot = each.value.onboot
  pool_id       = each.value.pool
  tags          = each.value.tags_list

  features {
    nesting = each.value.unprivileged
  }

  cpu {
    cores = each.value.cpu
  }

  memory {
    dedicated = each.value.ram_mb
  }

  disk {
    datastore_id = each.value.storage
    size         = each.value.disk_gb
  }

  initialization {
    hostname = each.value.ct_name
    ip_config {
      ipv4 {
        address = each.value.ipv4
        gateway = each.value.ipv4_gateway
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = each.value.bridge
  }

  operating_system {
    template_file_id = each.value.os_template
    type             = "unmanaged"
  }
}
