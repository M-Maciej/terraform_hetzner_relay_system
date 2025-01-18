module "network" {
  source = "./network"

  # Pass any required variables for the network module here
  # Example:
  # vpc_name = "my-network-vpc"
  hcloud_token = var.hcloud_token
}

module "bastion" {
  source = "./bastion"

  # Pass the output from the network module as input to the bastion module
  network_id             = module.network.network_id

  # Pass any other required variables for the bastion module here
  hcloud_token = var.hcloud_token
  bastion_public_key_path = var.bastion_public_key_path
}

module "internal" {
  source = "./internal"

  # Pass the output from the network module as input to the bastion module
  network_id             = module.network.network_id

  # Pass the output from the bastion module as input to the bastion module
  bastion_ready_id = module.bastion.bastion_ready_id
  
  # Pass any other required variables for the internal module here
  hcloud_token = var.hcloud_token
  internal_public_key_path = var.internal_public_key_path

}

module "application" {
  source                    = "./application"
  network_id                = module.network.network_id
  hcloud_token              = var.hcloud_token
  application_public_key_path = var.application_public_key_path

  # Wait for internal to be done
  internal_ready_id         = module.internal.internal_ready_id
}