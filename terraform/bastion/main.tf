##############################
# Requirements & Provider
##############################
terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.49"
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

##############################
# 1) Bastion SSH Key
##############################
resource "hcloud_ssh_key" "bastion_ssh" {
  name       = "bastion_root_key"
  public_key = file(var.bastion_public_key_path)
}

##############################
# 2) Bastion Server
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
    network_id = var.network_id
  }
  
  # (A) Remote-exec: Generate an ECDSA key "id_internal_ecdsa" on the *bastion* server
  provisioner "remote-exec" {
    inline = [
      "ssh-keygen -t ecdsa -N '' -f /root/.ssh/id_internal_ecdsa",
      "cat /root/.ssh/id_internal_ecdsa.pub > /tmp/id_internal_ecdsa_public_key.pub"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/bastion_key_temp") # The matching private key from your local machine
      host        = self.ipv4_address
    }
  }

  # (B) Local-exec: Copy that pubkey back to local
  provisioner "local-exec" {
    command = <<-EOT
      scp \
        -i ~/.ssh/bastion_key_temp \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        root@${self.ipv4_address}:/tmp/id_internal_ecdsa_public_key.pub \
        ./id_internal_ecdsa_public_key.pub
    EOT
  }
}
resource "null_resource" "bastion_ready" {
  depends_on = [hcloud_server.bastion]
}

resource "hcloud_server_network" "bastion_net" {
  server_id  = hcloud_server.bastion.id
  network_id = var.network_id
}
