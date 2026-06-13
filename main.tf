# =============================================================================
# PRVI KORAK: test konekcije Terraform -> OpenStack
#  - procita vanjsku (public) mrezu  -> dokazuje da auth/citanje radi
#  - napravi 2 vCPU / 4 GB flavor     -> dokazuje da kreiranje radi (admin)
# Kasnije se dograduju: projekti/korisnici, mreze po developeru, VM-ke,
# load balancer (Octavia), object/file storage, security grupe...
# =============================================================================

# Vanjska mreza za floating IP-ove (javni pristup jump hostu).
data "openstack_networking_network_v2" "external" {
  name = "provider-datacentre"
}

# Lab nudi samo 2 GB flavore, a projekt trazi 2 vCPU / 4 GB.
# Kao admin radimo vlastiti flavor.
resource "openstack_compute_flavor_v2" "moodle" {
  name      = "moodle.2c4g"
  ram       = 4096 # MB
  vcpus     = 2
  disk      = 20 # GB root disk
  is_public = true
}

# Mali flavor za jump i LB VM-ke (njima ne treba 4 GB) - stedi resurse u labu.
# RAM = rhel8 min_ram (image to zahtijeva); 2048 je tipicno za RHEL.
resource "openstack_compute_flavor_v2" "small" {
  name      = "techsprint.small"
  ram       = 2048 # MB
  vcpus     = 1
  disk      = 20 # GB
  is_public = true
}

output "external_network_id" {
  description = "ID vanjske mreze (provider-datacentre)."
  value       = data.openstack_networking_network_v2.external.id
}

output "moodle_flavor_id" {
  description = "ID novog 2 vCPU / 4 GB flavora."
  value       = openstack_compute_flavor_v2.moodle.id
}
