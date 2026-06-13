variable "project_prefix" {
  type        = string
  description = "Prefiks za nazive resursa/projekata."
  default     = "techsprint"
}

variable "users_csv_path" {
  type        = string
  description = "Putanja do CSV-a: ime;prezime;rola"
  default     = "users.csv"
}

variable "domain_id" {
  type        = string
  description = "Keystone domena za projekte i korisnike."
  default     = "default"
}

variable "default_user_password" {
  type        = string
  description = "Lab lozinka za kreirane korisnike. Za pravu upotrebu postavi u terraform.tfvars."
  default     = "TechSprint123!"
  sensitive   = true
}
