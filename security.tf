# =============================================================================
# SECURITY GRUPE (firewall pravila)
#  - jump: SSH izvana (jedini javno dostupan)
#  - app:  SSH samo iz lead mreze (preko jumpa), HTTP unutar developer mreze
# =============================================================================

# ---------- JUMP ----------

resource "openstack_networking_secgroup_v2" "jump" {
  name        = "${var.project_prefix}-jump-sg"
  description = "Jump host: SSH izvana"
}

resource "openstack_networking_secgroup_rule_v2" "jump_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.jump.id
}

resource "openstack_networking_secgroup_rule_v2" "jump_icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.jump.id
}

# ---------- APP (Moodle VM-ke) ----------

resource "openstack_networking_secgroup_v2" "app" {
  name        = "${var.project_prefix}-app-sg"
  description = "App VM: SSH iz lead mreze, HTTP unutar developer mreza"
}

# SSH iz lead/management mreze
resource "openstack_networking_secgroup_rule_v2" "app_ssh_from_lead" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = local.lead_cidr
  security_group_id = openstack_networking_secgroup_v2.app.id
}

# SSH iz vlastite developer mreze - jump je multi-home na dev mrezi, pa ovim
# moze SSH-ati app VM-ke (za upravljanje/debug). Ostaje izolirano po developeru.
resource "openstack_networking_secgroup_rule_v2" "app_ssh_from_dev" {
  for_each = local.developers

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = each.value.cidr
  security_group_id = openstack_networking_secgroup_v2.app.id
}

# HTTP (port 80) iz lead mreze i unutar svih developer mreza
resource "openstack_networking_secgroup_rule_v2" "app_http_from_lead" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = local.lead_cidr
  security_group_id = openstack_networking_secgroup_v2.app.id
}

resource "openstack_networking_secgroup_rule_v2" "app_http_from_dev" {
  for_each = local.developers

  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = each.value.cidr
  security_group_id = openstack_networking_secgroup_v2.app.id
}

# ICMP (ping) iz lead mreze - korisno za debug s jump hosta
resource "openstack_networking_secgroup_rule_v2" "app_icmp_from_lead" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = local.lead_cidr
  security_group_id = openstack_networking_secgroup_v2.app.id
}
