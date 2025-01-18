output "bastion_public_ip" {
  description = "The public IPv4 address of the bastion (if enabled)"
  value       = hcloud_server.application.ipv4_address
}

