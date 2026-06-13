# IRUO – OpenStack Terraform (TechSprint Moodle okolina)

OpenStack dio IRUO projekta (Red Hat OpenStack Platform 16.1). Automatizirani
deployment iz CSV datoteke (developeri + DevOps lead): jump host (floating IP),
izolirane mreže po developeru, 2 Moodle VM-ke po developeru, load balancer,
object + backup storage (Swift), diskovi (Cinder) i IAM (Keystone projekti,
korisnici, role).

> Pokreće se **iz laba (workstation noda)**, jer je OpenStack API unutar laba.

## Preduvjeti

- Pristup OpenStack okolini (Horizon + `admin-rc` na workstationu)
- Terraform (instalira se na workstation, vidi dolje)

## Pokretanje (na workstation nodu)

Instalacija Terraforma (samo prvi put):

```bash
curl -fsSL https://releases.hashicorp.com/terraform/1.9.8/terraform_1.9.8_linux_amd64.zip -o /tmp/tf.zip
mkdir -p ~/bin && (cd /tmp && unzip -o tf.zip) && mv /tmp/terraform ~/bin/
export PATH="$HOME/bin:$PATH"
terraform version
```

Učitavanje OpenStack kredencijala:

```bash
source ~/admin-rc
```

Deploy:

```bash
terraform init
terraform plan
terraform apply
```

## Čišćenje

```bash
terraform destroy
```

## Napomena

Kredencijali (`admin-rc`, `clouds.yaml`), state i ključevi su u `.gitignore` i
ne idu na GitHub. Auth Terraform čita iz env varijabli koje postavi
`source ~/admin-rc`.
