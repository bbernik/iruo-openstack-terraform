terraform {
  required_version = ">= 1.3"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}

# Autentikacija se cita iz environment varijabli koje postavi `source ~/admin-rc`
# (OS_AUTH_URL, OS_USERNAME, OS_PASSWORD, OS_PROJECT_NAME, OS_*_DOMAIN_NAME ...).
# Tako lozinka NE zavrsava u kodu ni na GitHubu.
provider "openstack" {}
