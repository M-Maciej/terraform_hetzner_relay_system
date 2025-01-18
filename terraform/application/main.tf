terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "application_ssh" {
  name       = "aplication_root_key"
  public_key = file(var.application_public_key_path)
}
resource "null_resource" "wait_for_internal" {
  # This says "Don't create me until bastion_ready_id is known"
  # The resource you reference (null_resource.bastion_ready in the other module)
  # is completed, meaning the local-exec is done.
  triggers = {
    internal_ready_id = var.internal_ready_id
  }
}

data "local_file" "application_public_key_relay" {
  filename   = "./id_application_ecdsa_public_key.pub"
  depends_on = [null_resource.wait_for_internal]
}


resource "hcloud_ssh_key" "application_ssh_relay" {
  depends_on = [data.local_file.application_public_key_relay]
  name       = "application_ssh_key_from_internal"
  public_key = data.local_file.application_public_key_relay.content
}
resource "hcloud_server" "application" {
  depends_on = [data.local_file.application_public_key_relay]
  name       = "application-host"
  server_type = "cx22"
  image      = "ubuntu-24.04"
  location   = "fsn1"

  ssh_keys = [
    hcloud_ssh_key.application_ssh.name,
    hcloud_ssh_key.application_ssh_relay.name
  ]

  
}
resource "hcloud_server_network" "application_net" {
  server_id  = hcloud_server.application.id
  network_id = var.network_id
  ip         = "10.0.1.5"
}