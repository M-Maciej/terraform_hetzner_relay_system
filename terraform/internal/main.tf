terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_ssh_key" "internal_ssh" {
  name       = "internal_root_key"
  public_key = file(var.internal_public_key_path)
}

resource "hcloud_server" "internal" {
  depends_on = [hcloud_server.bastion]
  name       = "internal-relay"
  server_type = "cx22"
  image      = "ubuntu-24.04"
  location   = "fsn1"

  # Use BOTH the local key + the relay key from the bastion
  ssh_keys = [
    hcloud_ssh_key.internal_ssh.name,
    hcloud_ssh_key.internal_ssh_relay.name
  ]


  network {
    network_id = hcloud_network.vpc.id
  }
  # (A) Remote-exec: Generate "id_application_ecdsa" on the *internal* server
  provisioner "remote-exec" {
    inline = [
      "ssh-keygen -t ecdsa -N '' -f /root/.ssh/id_application_ecdsa",
      "cat /root/.ssh/id_application_ecdsa.pub > /tmp/id_application_ecdsa_public_key.pub"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/internal_key_temp")
      host        = self.ipv4_address
    }
  }

  # (B) Local-exec: Copy that pubkey back to local
  provisioner "local-exec" {
    command = <<-EOT
      scp \
        -i ~/.ssh/internal_key_temp \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        root@${self.ipv4_address}:/tmp/id_application_ecdsa_public_key.pub \
        ./id_application_ecdsa_public_key.pub
    EOT
  }
}

resource "hcloud_server_network" "internal_net" {
  server_id  = hcloud_server.internal.id
  network_id = var.network_id
}
