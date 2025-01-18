variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "network_id" {
  type        = number
  description = "ID of the Hetzner network from the network module"
}

variable "application_public_key_path" {
  type        = string
  description = "Local path to the bastion's public SSH key"
}

variable "internal_ready_id" {
  type        = string
  description = "Wait for bastion's local-exec to finish"
}

