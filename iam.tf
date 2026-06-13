# =============================================================================
# IAM: projekti, korisnici i role iz CSV-a (Keystone)
#  - svaki developer dobije svoj IZOLIRANI projekt + korisnika (role: member)
#  - svaki lead dobije svoj projekt + pristup (member) na SVE developer projekte
# =============================================================================

# Postojeca "member" role (za obicne korisnike u projektu).
data "openstack_identity_role_v3" "member" {
  name = "member"
}

# -------------------- DEVELOPERI --------------------

resource "openstack_identity_project_v3" "developer" {
  for_each = local.developers

  name        = "${var.project_prefix}-${each.value.ime}-${each.value.prezime}"
  description = "Izolirani projekt za developera ${each.value.ime} ${each.value.prezime}"
  domain_id   = var.domain_id
}

resource "openstack_identity_user_v3" "developer" {
  for_each = local.developers

  name               = "${each.value.ime}.${each.value.prezime}"
  description        = "Developer ${each.value.ime} ${each.value.prezime}"
  default_project_id = openstack_identity_project_v3.developer[each.key].id
  password           = var.default_user_password
  domain_id          = var.domain_id
}

# Developer ima member role na SVOM projektu (i samo svom).
resource "openstack_identity_role_assignment_v3" "developer_member" {
  for_each = local.developers

  user_id    = openstack_identity_user_v3.developer[each.key].id
  project_id = openstack_identity_project_v3.developer[each.key].id
  role_id    = data.openstack_identity_role_v3.member.id
}

# -------------------- LEAD (voditelj) --------------------

resource "openstack_identity_project_v3" "lead" {
  for_each = local.leads

  name        = "${var.project_prefix}-lead-${each.value.ime}-${each.value.prezime}"
  description = "Projekt voditelja tima ${each.value.ime} ${each.value.prezime}"
  domain_id   = var.domain_id
}

resource "openstack_identity_user_v3" "lead" {
  for_each = local.leads

  name               = "${each.value.ime}.${each.value.prezime}"
  description        = "DevOps lead ${each.value.ime} ${each.value.prezime}"
  default_project_id = openstack_identity_project_v3.lead[each.key].id
  password           = var.default_user_password
  domain_id          = var.domain_id
}

# Lead dobije member role na SVAKOM developer projektu -> vidi/upravlja svime.
resource "openstack_identity_role_assignment_v3" "lead_on_dev_projects" {
  for_each = {
    for pair in setproduct(keys(local.leads), keys(local.developers)) :
    "${pair[0]}__${pair[1]}" => { lead = pair[0], dev = pair[1] }
  }

  user_id    = openstack_identity_user_v3.lead[each.value.lead].id
  project_id = openstack_identity_project_v3.developer[each.value.dev].id
  role_id    = data.openstack_identity_role_v3.member.id
}

# -------------------- OUTPUTS --------------------

output "developer_projects" {
  description = "Kreirani projekti po developeru."
  value       = { for k, p in openstack_identity_project_v3.developer : k => p.name }
}

output "created_users" {
  description = "Kreirani korisnici (developeri + lead)."
  value = concat(
    [for u in openstack_identity_user_v3.developer : u.name],
    [for u in openstack_identity_user_v3.lead : u.name]
  )
}
