terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.2"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

##############################
# 1) Network & Subnet
##############################

resource "hcloud_network" "vpc" {
  name     = "multiple_jump_network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "multiple_jump_network_subnet" {
  network_id   = hcloud_network.vpc.id
  type         = "cloud"
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

##############################
# 2) Bastion SSH Key (root)
##############################
# This is the local public key you already have on your machine
resource "hcloud_ssh_key" "bastion_ssh" {
  name       = "bastion_root_key"
  public_key = file("~/.ssh/id_bastion_ecdsa.pub")
}

##############################
# 3) Minimal Cloud-Init
##############################

locals {
  bastion_config_file = "${path.module}/bastion_config.yaml"
  bastion_user_data   = file(local.bastion_config_file)
}

##############################
# 4) Bastion Server
##############################
resource "hcloud_server" "bastion" {
  name        = "bastion-host"
  server_type = "cx22"
  image       = "ubuntu-24.04"
  location    = "fsn1"

  # Inject your root SSH key to Hetzner
  ssh_keys = [
    hcloud_ssh_key.bastion_ssh.name
  ]

  network {
    network_id = hcloud_network.vpc.id
  }

  # Cloud-init user_data to disable password auth, etc.
  user_data = local.bastion_user_data
  
  # 4a) Remote-exec: Generate an ECDSA key "id_internal_ecdsa" on the bastion.
  provisioner "remote-exec" {
    inline = [
      "ssh-keygen -t ecdsa -N '' -f /root/.ssh/id_internal_ecdsa",
      "cat /root/.ssh/id_internal_ecdsa.pub > /tmp/id_internal_ecdsa_public_key.pub"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/id_bastion_ecdsa") # The matching private key on your local machine
      host        = self.ipv4_address
    }
  }

  # 4b) Local-exec: Copy that pubkey to your local Terraform folder
  provisioner "local-exec" {
    command = <<-EOT
      scp \
        -i ~/.ssh/id_bastion_ecdsa \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        root@${self.ipv4_address}:/tmp/id_internal_ecdsa_public_key.pub \
        ./id_internal_ecdsa_public_key.pub
    EOT
  }
}

##############################
# 5) Data Source: local_file
##############################
data "local_file" "internal_public_key" {
  # Must match the file name from local-exec scp
  filename = "${path.module}/id_internal_ecdsa_public_key.pub"
}

##############################
# 6) Create an hcloud SSH Key (internal)
##############################
resource "hcloud_ssh_key" "internal_ssh" {
  depends_on = [hcloud_server.bastion]

  name       = "internal_ssh_key"
  public_key = data.local_file.internal_public_key.content
}

##############################
# 7) Internal Relay Server
##############################
resource "hcloud_server" "internal" {
  depends_on = [hcloud_server.bastion]
  name       = "internal-relay"
  server_type = "cx22"
  image      = "ubuntu-24.04"
  location   = "fsn1"

  # Use the newly created SSH key from above
  ssh_keys = [
    hcloud_ssh_key.internal_ssh.name
  ]

  network {
    network_id = hcloud_network.vpc.id
  }
}
