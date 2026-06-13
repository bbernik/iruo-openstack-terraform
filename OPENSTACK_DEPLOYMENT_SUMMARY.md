# OpenStack Deployment Summary (IRUO projekt)

Red Hat OpenStack Platform 16.1 (CL110 lab). Terraform deployment koji preslikava
istu arhitekturu kao Azure dio projekta.

## Što radi (provjereno)

| Zahtjev | Implementacija | Status |
|---|---|---|
| IAM – korisnici/projekti/role iz CSV-a | Keystone: projekt + korisnik (member) po developeru; lead member na svim dev projektima | ✅ |
| Mrežna izolacija po developeru | zasebna Neutron mreza/subnet/router po developeru | ✅ |
| Jump host (bastion), jedini javni | RHEL8 VM + floating IP na lead mrezi | ✅ |
| Jump doseze sve dev VM-ke | multi-home: port jump hosta na svakoj dev mrezi | ✅ |
| 2 Moodle VM-ke po developeru (2 vCPU / 4 GB) | `openstack_compute_instance_v2` (flavor moodle.2c4g) | ✅ |
| Dva diska po VM-ki | OS disk + Cinder data volume (/data) | ✅ |
| Load balancer po developeru | LB VM s Python TCP round-robin (vidi nize) | ✅ |
| Izlaz na internet | router sa SNAT-om na vanjsku mrezu | ✅ |
| Object storage po developeru | Swift container (moodle-objects) | ✅ |
| Backup storage po developeru | Swift container (moodle-backups) | ✅ |

Test (s jump hosta): `curl http://<LB_IP>` izmjenjuje `app1`/`app2` -> load balancer radi.

## Ograničenja laba (dokumentirano)

Dvije OpenStack usluge nisu iskoristive u ovom CL110 labu, pa su zamijenjene:

### 1. Octavia (LBaaS) ne radi
Octavia amphora load balanceri zavrse u `ERROR` statusu (`context deadline
exceeded` pri cekanju na ACTIVE) — amphora VM-ovi se ne dizu u ogranicenom labu.

**Zamjena:** LB VM po developeru s laganim TCP round-robin balancerom u Pythonu
(`cloud-init-lb.yaml.tpl`). Bez ovisnosti o paketima, pouzdano radi. Cest pristup
(HAProxy/nginx VM umjesto cloud LBaaS).

### 2. Manila (file share) nema share type
`manila type-list` je prazan — nijedan share type/backend nije konfiguriran za
tenant koristenje, pa se ne mogu kreirati file shareovi.

**Zamjena:** backupi koriste zaseban Swift container. U Manila-enabled okruzenju
ovo bi bio NFS share montiran na VM-ke.

### 3. Moodle container (bitnami) ne radi pod podman/SELinux

Provjereno je da app VM-ke MOGU pokretati kontejnere (`podman` se instalira,
Docker Hub je dostupan, image se povlaci). Ali bitnami Moodle image
(`bitnamilegacy/moodle:4.5`, isti koji radi na Azure/Docker dijelu) pod
podman + RHEL8 SELinux trajno pada s:

```
WARN ==> The Apache configuration file '/opt/bitnami/apache/conf/httpd.conf' is not writable.
ERROR ==> Could not add the following configuration ...
```

Uzrok: image se vrti kao root pa setup interno padne na korisnika 1001, a config
datoteke su `root:root` -> 1001 ih ne moze pisati. Isproban niz fixeva
(`--user 0`, `--security-opt label=disable`, chown `/opt/bitnami` wrapper, `:Z`
volumeni) - nijedan ne rjesava. Na Azureu (Docker/Ubuntu, bez SELinuxa) isti
image radi.

**Zakljucak:** aplikacijski sloj (Moodle) je na OpenStack strani **dokazan kroz
infrastrukturu** — test web server na portu 80 dokazuje da put
`jump -> load balancer -> app VM (port 80)` radi i round-robina izmedu obje
instance. **Pravi Moodle (HTTP 200) radi na Azure dijelu projekta.** U
produkcijskom OpenStacku rjesenje bi bilo Moodle image koji radi kao root ili
custom image s ispravnim vlasnistvom `/opt/bitnami`.

## Pokretanje (na lab workstationu)

```bash
# Terraform (jednom):
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo dnf install -y terraform

git clone https://github.com/bbernik/iruo-openstack-terraform.git
cd iruo-openstack-terraform
source ~/admin-rc
terraform init
terraform apply
```

## Test

```bash
terraform output jump_floating_ip
terraform output developer_load_balancers

terraform output -raw ssh_private_key > ~/techsprint-key.pem
chmod 600 ~/techsprint-key.pem
ssh -i ~/techsprint-key.pem cloud-user@<JUMP_IP>

# s jump hosta:
for i in 1 2 3 4; do curl -s http://<LB_IP>; done
```

## Resursi / kapacitet

Lab ima ogranicen compute (cores=20, ram=51200 MB, instances=10). Zato su jump i
LB VM-ke na malom flavoru (`techsprint.small`, 1 vCPU / 2 GB), a samo app
(Moodle) VM-ke na `moodle.2c4g` (2 vCPU / 4 GB), kako trazi projekt.
Ukupno 7 VM-ki: jump + 4 app + 2 LB.
