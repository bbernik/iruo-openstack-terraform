# =============================================================================
# MREZE
#  - lead/management mreza za jump host
#  - izolirana mreza po developeru (medusobno se NE vide)
#  - svaka mreza ima router na vanjsku mrezu (outbound internet preko SNAT-a)
# =============================================================================

# ---------- LEAD / MANAGEMENT mreza (jump host) ----------

resource "openstack_networking_network_v2" "lead" {
  name = "${var.project_prefix}-lead-net"
}

resource "openstack_networking_subnet_v2" "lead" {
  name            = "${var.project_prefix}-lead-subnet"
  network_id      = openstack_networking_network_v2.lead.id
  cidr            = local.lead_cidr
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]
}

resource "openstack_networking_router_v2" "lead" {
  name                = "${var.project_prefix}-lead-router"
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "lead" {
  router_id = openstack_networking_router_v2.lead.id
  subnet_id = openstack_networking_subnet_v2.lead.id
}

# ---------- DEVELOPER mreze (izolirane) ----------

resource "openstack_networking_network_v2" "developer" {
  for_each = local.developers

  name = "${var.project_prefix}-${each.value.ime}-${each.value.prezime}-net"
}

resource "openstack_networking_subnet_v2" "developer" {
  for_each = local.developers

  name            = "${var.project_prefix}-${each.value.ime}-${each.value.prezime}-subnet"
  network_id      = openstack_networking_network_v2.developer[each.key].id
  cidr            = each.value.cidr
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "1.1.1.1"]
}

resource "openstack_networking_router_v2" "developer" {
  for_each = local.developers

  name                = "${var.project_prefix}-${each.value.ime}-${each.value.prezime}-router"
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "developer" {
  for_each = local.developers

  router_id = openstack_networking_router_v2.developer[each.key].id
  subnet_id = openstack_networking_subnet_v2.developer[each.key].id
}
