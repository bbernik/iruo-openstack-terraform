# =============================================================================
# STORAGE
#  - Swift (object): container po developeru za Moodle datoteke
#  - Manila (file):  share po developeru za backupe  -> dodaje se nakon
#    provjere da lab ima konfiguriran share type
# =============================================================================

# ---------- OBJECT STORAGE (Swift) ----------
# Container za Moodle objektne datoteke.
resource "openstack_objectstorage_container_v1" "moodle_objects" {
  for_each = local.developers

  name = "${var.project_prefix}-${each.value.ime}-${each.value.prezime}-objects"

  metadata = {
    owner   = each.key
    purpose = "moodle-objects"
  }
}

# ---------- FILE / BACKUP STORAGE ----------
# Manila (native file-share servis) nema konfiguriran share type u ovom labu
# (dokaz: `manila type-list` je prazan), pa backupi koriste zaseban Swift
# container. U Manila-enabled okruzenju ovo bi bio NFS share montiran na VM-ke.
resource "openstack_objectstorage_container_v1" "backups" {
  for_each = local.developers

  name = "${var.project_prefix}-${each.value.ime}-${each.value.prezime}-backups"

  metadata = {
    owner   = each.key
    purpose = "moodle-backups"
  }
}

output "object_storage_containers" {
  description = "Swift container (object storage) po developeru."
  value       = { for k, c in openstack_objectstorage_container_v1.moodle_objects : k => c.name }
}

output "backup_storage_containers" {
  description = "Swift container za backupe po developeru."
  value       = { for k, c in openstack_objectstorage_container_v1.backups : k => c.name }
}
