locals {
  # Procitaj CSV, makni prazne i komentar (#) linije, normaliziraj kraj retka.
  csv_lines = [
    for line in split("\n", replace(file("${path.module}/${var.users_csv_path}"), "\r\n", "\n")) :
    trimspace(line)
    if trimspace(line) != "" && !startswith(trimspace(line), "#")
  ]

  # Preskoci header (prvi red), razdvoji po ;
  csv_rows = [
    for line in slice(local.csv_lines, 1, length(local.csv_lines)) : split(";", line)
  ]

  users = [
    for row in local.csv_rows : {
      ime     = lower(trimspace(row[0]))
      prezime = lower(trimspace(row[1]))
      rola    = lower(trimspace(row[2]))
      key     = "${lower(trimspace(row[0]))}-${lower(trimspace(row[1]))}"
    }
  ]

  # Developeri s indeksom i izvedenim CIDR-om (192.168.<10+idx>.0/24).
  developers = {
    for idx, u in [for x in local.users : x if x.rola == "developer"] :
    u.key => merge(u, {
      index = idx
      cidr  = "192.168.${idx + 10}.0/24"
    })
  }

  leads = { for u in local.users : u.key => u if u.rola == "devops_lead" }

  # CIDR lead/management mreze (jump host).
  lead_cidr = "192.168.100.0/24"

  # 2 app (Moodle) instance po developeru.
  app_instances = merge([
    for dev_key, dev in local.developers : {
      for n in [1, 2] : "${dev_key}-app${n}" => {
        dev_key = dev_key
        n       = n
        name    = "${var.project_prefix}-${dev.ime}-${dev.prezime}-app${n}"
      }
    }
  ]...)
}
