# VM workload: creates proxmox_virtual_environment_vm resources (bpg/proxmox provider).
# Name: <client>-<env>-<dc>-<role>-<nn>. Tags: same sanitized base as LXC + per-VM metadata.
# See: https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm
locals {
  sanitize_re = "/[^a-z0-9_.:-]/"
  # dc in dc01, dc02 format (datacenter_short from datacenter_vars; "datacenter-01" -> dc01).
  dc_normalized    = replace(lower(var.datacenter_short), "datacenter-", "dc")
  default_ssh_path = try(trimspace(var.default_ssh_pubkey_path), "")

  expanded_vm_instances = flatten([
    for group_name, group in var.vm_groups : [
      for index in range(group.count) : {
        group_name     = group_name
        role           = group.role
        ordinal        = index + 1
        index2         = format("%02d", index + 1)
        cpu            = group.cpu
        ram_mb         = group.ram_mb
        disk_gb        = group.disk_gb
        use_clone      = coalesce(try(group.use_clone, null), false)
        template       = coalesce(try(group.template, null), var.default_template)
        template_vm_id = try(group.template_vm_id, null) != null ? group.template_vm_id : var.default_template_vm_id
        cloning        = coalesce(try(group.use_clone, null), false) && (try(group.template_vm_id, var.default_template_vm_id) != null)

        target_node = (
          length(try(group.target_nodes, [])) > 0
          ? group.target_nodes[index % length(group.target_nodes)]
          : coalesce(try(group.node, null), var.default_node, try(var.default_target_nodes[0], null))
        )

        bridge  = coalesce(try(group.bridge, null), var.default_bridge)
        storage = coalesce(try(group.storage, null), var.default_storage)
        pool    = try(coalesce(try(group.pool, null), var.default_pool), null)

        machine                 = coalesce(try(group.machine, null), var.default_machine)
        sockets                 = coalesce(try(group.sockets, null), var.default_sockets)
        cpu_type                = coalesce(try(group.cpu_type, null), var.default_cpu_type)
        agent_enabled           = coalesce(try(group.agent_enabled, null), var.default_agent_enabled)
        scsihw                  = coalesce(try(group.scsihw, null), var.default_scsihw)
        disk_iothread           = coalesce(try(group.disk_iothread, null), var.default_disk_iothread)
        start_on_create         = coalesce(try(group.start_on_create, null), var.default_start_on_create)
        wait_for_agent          = coalesce(try(group.wait_for_agent, null), var.default_wait_for_agent)
        agent_timeout           = coalesce(try(group.agent_timeout, null), var.default_agent_timeout)
        cloud_init_set_hostname = coalesce(try(group.cloud_init_set_hostname, null), var.default_cloud_init_set_hostname)
        group_ssh_path          = try(trimspace(group.ssh_pubkey_path), "")
        extra_disks = [
          for disk in try(group.extra_disks, []) : {
            interface = lower(trimspace(disk.interface))
            datastore_id = (
              try(trimspace(disk.datastore_id), "") != ""
              ? trimspace(disk.datastore_id)
              : coalesce(try(group.storage, null), var.default_storage)
            )
            size_gb  = disk.size_gb
            iothread = coalesce(try(disk.iothread, null), var.default_disk_iothread)
            discard  = coalesce(try(disk.discard, null), var.default_disk_discard)
            ssd      = coalesce(try(disk.ssd, null), var.default_disk_ssd)
          }
        ]
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
            resource_type = "vm"
            group         = replace(lower(group_name), local.sanitize_re, "_")
            index         = format("%02d", index + 1)
            template_os   = (coalesce(try(group.use_clone, null), false) && (try(group.template_vm_id, var.default_template_vm_id) != null)) ? "yes" : "no"
          }
        )

        # Required convention: <client>-<env>-<dc>-<role>-<nn>
        vm_name = lower(join(var.naming_delimiter, [
          var.client,
          var.environment,
          local.dc_normalized,
          group.role,
          format("%02d", index + 1),
        ]))

        enabled = try(group.enabled, true)
      }
    ]
  ])

  # Global ordinal (flatten idx) -> unique vm_id. Tags: sanitized base + per-resource metadata.
  all_vm_instances = {
    for idx, instance in local.expanded_vm_instances :
    "${instance.group_name}-${instance.index2}" => merge(instance, {
      vm_id           = var.default_vm_id_base + idx + 1
      ssh_pubkey_path = instance.group_ssh_path != "" ? instance.group_ssh_path : (local.default_ssh_path != "" ? local.default_ssh_path : null)
      tags_list       = sort([for k, v in instance.tags : "${k}-${v}"])
    })
    if instance.enabled
  }
}

resource "proxmox_virtual_environment_file" "cloud_init_meta" {
  for_each = {
    for key, instance in local.all_vm_instances : key => instance
    if instance.cloning && instance.cloud_init_set_hostname
  }

  content_type = "snippets"
  datastore_id = var.default_cloud_init_snippets_storage
  node_name    = each.value.target_node
  overwrite    = true

  source_raw {
    file_name = "ci-meta-${each.value.vm_id}.yaml"
    data = yamlencode({
      "instance-id"    = "vm-${each.value.vm_id}"
      "local-hostname" = each.value.vm_name
    })
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.all_vm_instances

  name      = each.value.vm_name
  node_name = each.value.target_node
  vm_id     = each.value.vm_id

  tags = each.value.tags_list

  machine = each.value.machine
  on_boot = true
  # Start only when there is a template (cloning); an empty VM without an OS must not remain powered on.
  started = each.value.cloning && coalesce(each.value.start_on_create, true)
  pool_id = each.value.pool

  # Agent: enablement and waiting are controlled separately.
  # Only wait when the VM comes from a template and the agent will actually be enabled.
  # In the "do not wait" branch, use timeout 0 to avoid long waits in the provider.
  agent {
    enabled = each.value.agent_enabled
    timeout = (each.value.cloning && each.value.agent_enabled && each.value.wait_for_agent) ? each.value.agent_timeout : "0s"
    trim    = each.value.cloning
  }

  cpu {
    cores   = each.value.cpu
    sockets = each.value.sockets
    type    = each.value.cpu_type
  }

  memory {
    dedicated = each.value.ram_mb
    floating  = each.value.ram_mb
  }

  dynamic "disk" {
    for_each = each.value.use_clone && each.value.template_vm_id != null ? [] : [1]
    content {
      datastore_id = each.value.storage
      interface    = "scsi0"
      size         = each.value.disk_gb
      iothread     = each.value.disk_iothread
      discard      = var.default_disk_discard
      ssd          = var.default_disk_ssd
    }
  }

  dynamic "disk" {
    for_each = {
      for disk in each.value.extra_disks : disk.interface => disk
    }
    content {
      datastore_id = disk.value.datastore_id
      interface    = disk.value.interface
      size         = disk.value.size_gb
      iothread     = disk.value.iothread
      discard      = disk.value.discard
      ssd          = disk.value.ssd
    }
  }

  network_device {
    bridge = each.value.bridge
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }

  scsi_hardware = each.value.scsihw

  serial_device {}

  dynamic "clone" {
    for_each = each.value.use_clone && each.value.template_vm_id != null ? [1] : []
    content {
      vm_id        = each.value.template_vm_id
      full         = true
      datastore_id = each.value.storage
    }
  }

  # Cloud-init: only when there is a template. DHCP by default; SSH keys when ssh_pubkey_path is set.
  dynamic "initialization" {
    for_each = each.value.cloning ? [1] : []
    content {
      meta_data_file_id = try(proxmox_virtual_environment_file.cloud_init_meta[each.key].id, null)
      ip_config {
        ipv4 {
          address = "dhcp"
        }
      }
      dynamic "user_account" {
        for_each = (
          try(trimspace(each.value.ssh_pubkey_path), "") != "" &&
          try(fileexists(trimspace(each.value.ssh_pubkey_path)), false)
        ) ? [1] : []
        content {
          username = "admin-ubuntu"
          keys     = [trimspace(file(trimspace(each.value.ssh_pubkey_path)))]
        }
      }
    }
  }
}
