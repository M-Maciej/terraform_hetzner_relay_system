variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "network_id" {
  type        = number
  description = "ID of the Hetzner network from the network module"
}

variable "internal_public_key_path" {
  type        = string
  description = "Local path to the bastion's public SSH key"
}

