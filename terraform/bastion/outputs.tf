output "bastion_public_ip" {
  description = "The public IPv4 address of the bastion (if enabled)"
  value       = hcloud_server.bastion.ipv4_address
}

output "bastion_id" {
  description = "The ID of the bastion server"
  value       = hcloud_server.bastion.id
}
