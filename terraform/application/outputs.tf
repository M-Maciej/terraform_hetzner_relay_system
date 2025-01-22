output "application_public_ip" {
  description = "The public IPv4 address of the bastion (if enabled)"
  value       = hcloud_server.application.ipv4_address
}

output "application_private_ip" {
  description = "the private ip address that internal connects to"
  value = hcloud_server_network.application_net.ip
}