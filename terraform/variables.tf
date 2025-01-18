variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "bastion_public_key_path" {
  type        = string
  description = "Local path to the bastion's public SSH key"
  default = "~/.ssh/bastion_key_temp.pub"
}

variable "internal_public_key_path" {
  type        = string
  description = "Local path to the internal's public SSH key"
  default = "~/.ssh/internal_key_temp.pub"
}

variable "application_public_key_path" {
  type        = string
  description = "Local path to the internal's public SSH key"
  default = "~/.ssh/application_key_temp.pub"
}

