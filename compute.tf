# =============================================================================
# COMPUTE: SSH keypair + jump host (bastion)
#  Dev Moodle VM-ke se dodaju u sljedecem koraku.
# =============================================================================

# RHEL 8 image za sve VM-ke.
data "openstack_images_image_v2" "rhel8" {
  name        = "rhel8"
  most_recent = true
}

# OpenStack sam generira keypair; privatni kljuc je u outputu (sensitive).
resource "openstack_compute_keypair_v2" "main" {
  name = "${var.project_prefix}-key"
}

# ---------- JUMP HOST ----------

# Eksplicitni port: na njega vezemo security grupu i floating IP (pouzdano).
resource "openstack_networking_port_v2" "jump" {
  name               = "${var.project_prefix}-jump-port"
  network_id         = openstack_networking_network_v2.lead.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.jump.id]

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.lead.id
  }
}

resource "openstack_compute_instance_v2" "jump" {
  name      = "${var.project_prefix}-jump"
  image_id  = data.openstack_images_image_v2.rhel8.id
  flavor_id = openstack_compute_flavor_v2.small.id
  key_pair  = openstack_compute_keypair_v2.main.name

  network {
    port = openstack_networking_port_v2.jump.id
  }

  # Multi-home: dodatni port na svakoj developer mrezi, da jump dosegne app VM-ke.
  dynamic "network" {
    for_each = openstack_networking_port_v2.jump_dev
    content {
      port = network.value.id
    }
  }

  depends_on = [openstack_networking_router_interface_v2.lead]
}

# Floating IP (javni) iz vanjske mreze, pridruzen portu jump hosta.
resource "openstack_networking_floatingip_v2" "jump" {
  pool = data.openstack_networking_network_v2.external.name
}

resource "openstack_networking_floatingip_associate_v2" "jump" {
  floating_ip = openstack_networking_floatingip_v2.jump.address
  port_id     = openstack_networking_port_v2.jump.id
}

# ---------- OUTPUTS ----------

output "jump_floating_ip" {
  description = "Javni (floating) IP jump hosta."
  value       = openstack_networking_floatingip_v2.jump.address
}

output "ssh_private_key" {
  description = "Privatni SSH kljuc za pristup VM-kama (sensitive). Username za RHEL: cloud-user."
  value       = openstack_compute_keypair_v2.main.private_key
  sensitive   = true
}
