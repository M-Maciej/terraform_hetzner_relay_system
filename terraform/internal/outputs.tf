output "internal_private_ip" {
  description = "Private IP of the internal server."
  value       = hcloud_server_network.internal_net.ip
}