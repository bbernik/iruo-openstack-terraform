# =============================================================================
# LOAD BALANCER (rezervni plan): LB VM po developeru
#  Octavia (amphora) ne radi pouzdano u ovom labu, pa koristimo malu VM-ku
#  s laganim TCP round-robin LB-om (Python). VIP = IP te LB VM-ke.
#  S jump hosta: curl http://<LB_IP>  -> izmjenjuje app1/app2.
# =============================================================================

resource "openstack_networking_port_v2" "lb" {
  for_each = local.developers

  name               = "port-${var.project_prefix}-${each.value.ime}-${each.value.prezime}-lb"
  network_id         = openstack_networking_network_v2.developer[each.key].id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.app.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.developer[each.key].id
  }
}

resource "openstack_compute_instance_v2" "lb" {
  for_each = local.developers

  name      = "${var.project_prefix}-${each.value.ime}-${each.value.prezime}-lb"
  image_id  = data.openstack_images_image_v2.rhel8.id
  flavor_id = openstack_compute_flavor_v2.small.id
  key_pair  = openstack_compute_keypair_v2.main.name

  user_data = templatefile("${path.module}/cloud-init-lb.yaml.tpl", {
    backends = join(", ", [
      for k, inst in local.app_instances :
      "(\"${openstack_networking_port_v2.app[k].all_fixed_ips[0]}\", 80)"
      if inst.dev_key == each.key
    ])
  })

  network {
    port = openstack_networking_port_v2.lb[each.key].id
  }

  depends_on = [openstack_networking_router_interface_v2.developer]
}

output "developer_load_balancers" {
  description = "IP load balancera (LB VM-ke) po developeru. Curl s jump hosta."
  value       = { for k, p in openstack_networking_port_v2.lb : k => p.all_fixed_ips[0] }
}
