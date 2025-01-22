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

resource "hcloud_ssh_key" "internal_ssh" {
  name       = "internal_root_key"
  public_key = file(var.internal_public_key_path)
}
resource "null_resource" "wait_for_bastion" {
  # This says "Don't create me until bastion_ready_id is known"
  # The resource you reference (null_resource.bastion_ready in the other module)
  # is completed, meaning the local-exec is done.
  triggers = {
    bastion_ready_id = var.bastion_ready_id
  }
}



data "local_file" "internal_public_key_relay" {
  filename   = "./id_internal_ecdsa_public_key.pub"
  depends_on = [null_resource.wait_for_bastion]
}


resource "hcloud_ssh_key" "internal_ssh_relay" {
  depends_on = [data.local_file.internal_public_key_relay]
  name       = "internal_ssh_key_from_bastion"
  public_key = data.local_file.internal_public_key_relay.content
}

resource "hcloud_server" "internal" {
  name       = "internal-relay"
  server_type = "cx22"
  image      = "ubuntu-24.04"
  location   = "fsn1"
  depends_on = [data.local_file.internal_public_key_relay]
  # Use BOTH the local key + the relay key from the bastion
  ssh_keys = [
    hcloud_ssh_key.internal_ssh.name,
    hcloud_ssh_key.internal_ssh_relay.name
  ]
  public_net {
    ipv4_enabled = false
    ipv6_enabled = true
  }

  network {
    network_id = var.network_id
  }
  # (A) Remote-exec: Generate "id_application_ecdsa" on the *internal* server
  provisioner "remote-exec" {
    inline = [
      "ssh-keygen -t ecdsa -N '' -f /root/.ssh/id_application_ecdsa",
      "cat /root/.ssh/id_application_ecdsa.pub > /tmp/id_application_ecdsa_public_key.pub",
      "sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 100/' /etc/ssh/ssh_config",
      # Restart the SSH service to apply changes
      "systemctl restart ssh"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("~/.ssh/internal_key_temp")
      host        = self.ipv6_address
    }
  }

  # (B) Local-exec: Copy that pubkey back to local
  provisioner "local-exec" {
    command = <<-EOT
      scp \
        -i ~/.ssh/internal_key_temp \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        root@[${self.ipv6_address}]:/tmp/id_application_ecdsa_public_key.pub \
        ./id_application_ecdsa_public_key.pub
    EOT
  }
}
resource "null_resource" "internal_ready" {
  depends_on = [hcloud_server.internal]
}
resource "hcloud_server_network" "internal_net" {
  server_id  = hcloud_server.internal.id
  network_id = var.network_id
}

