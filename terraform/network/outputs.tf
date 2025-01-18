output "network_id" {
  description = "The ID of the created Hetzner network"
  value       = hcloud_network.vpc.id
}

output "subnet_id" {
  description = "The ID of the created subnet"
  value       = hcloud_network_subnet.subnet.id
}
