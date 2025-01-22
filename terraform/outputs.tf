output "bastion_public_ip" {
  description = "The public IPv4 address of the bastion server"
  value       = module.bastion.bastion_public_ip
}

output "bastion_id" {
  description = "The ID of the bastion server"
  value       = module.bastion.bastion_id
}

output "bastion_ready_id" {
  description = "Signals that the bastion's local-exec provisioner has completed"
  value       = module.bastion.bastion_ready_id
}

output "internal_private_ip" {
  description = "The private IPv4 address of the internal server"
  value       = module.internal.internal_private_ip
}

output "internal_ready_id" {
  description = "Signals that the internal's local-exec provisioner has completed"
  value       = module.internal.internal_ready_id
}

output "application_public_ip" {
  description = "The public IPv4 address of the application server"
  value       = module.application.application_public_ip
}
output "application_private_ip" {
  description = "the private ip address that internal connects to"
  value = module.application.application_private_ip
}