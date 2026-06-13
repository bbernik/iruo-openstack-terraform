# =============================================================================
# APP (Moodle) VM-ke: 2 po developeru, na izoliranoj developer mrezi.
#  + jump multi-home portovi (da jump dosegne app VM-ke)
#  + data disk (Cinder) po VM-ki
# =============================================================================

# ---------- Jump multi-home: port na svakoj developer mrezi ----------
resource "openstack_networking_port_v2" "jump_dev" {
  for_each = local.developers

  name               = "${var.project_prefix}-jump-port-${each.value.ime}-${each.value.prezime}"
  network_id         = openstack_networking_network_v2.developer[each.key].id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.jump.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.developer[each.key].id
  }
}

# ---------- App portovi (app security grupa) ----------
resource "openstack_networking_port_v2" "app" {
  for_each = local.app_instances

  name               = "port-${each.value.name}"
  network_id         = openstack_networking_network_v2.developer[each.value.dev_key].id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.app.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.developer[each.value.dev_key].id
  }
}

# ---------- App instance ----------
resource "openstack_compute_instance_v2" "app" {
  for_each = local.app_instances

  name      = each.value.name
  image_id  = data.openstack_images_image_v2.rhel8.id
  flavor_id = openstack_compute_flavor_v2.moodle.id
  key_pair  = openstack_compute_keypair_v2.main.name
  user_data = file("${path.module}/cloud-init-app.yaml")

  network {
    port = openstack_networking_port_v2.app[each.key].id
  }

  depends_on = [openstack_networking_router_interface_v2.developer]
}

# ---------- Data disk (drugi disk) po VM-ki ----------
resource "openstack_blockstorage_volume_v3" "app_data" {
  for_each = local.app_instances

  name = "${each.value.name}-data"
  size = 10
}

resource "openstack_compute_volume_attach_v2" "app_data" {
  for_each = local.app_instances

  instance_id = openstack_compute_instance_v2.app[each.key].id
  volume_id   = openstack_blockstorage_volume_v3.app_data[each.key].id
}

# ---------- OUTPUTS ----------
output "app_private_ips" {
  description = "Privatni IP-ovi app VM-ki (dosegnuti s jump hosta)."
  value       = { for k, p in openstack_networking_port_v2.app : k => p.all_fixed_ips[0] }
}
