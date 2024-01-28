terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    #   version = "0.6.11"
    }
  }
}

resource "libvirt_volume" "bootstrap_root_disk" {
    name = "bootstrap_root"
    pool = var.root_pool
    size = var.root_disk_size

    provisioner "remote-exec" {
        inline = [
            "sudo dd if=${var.rootfs} of=/srv/libvirt/ssd/${self.name} oflag=direct bs=10M"
        ]

        connection {
            type        = "ssh"
            user        = "borisassogba"
            host        = var.host
            port        = 2222
            # Allow to use ssh private key protected by a passphrase
            # Please load this private key before
            # ssh-add = ~/.ssh/id_rsa
            agent       = true 
            # private_key = var.ssh_private_key
        }
    }
}


resource "libvirt_ignition" "bootstrap_ign" {
    pool = var.ign_pool
    name = "bootstrap.ign"
    content = var.ign_file
}

resource "libvirt_domain" "bootstrap" {
    name = "bootstrap"
    memory = 8192
    vcpu = 4

    coreos_ignition = libvirt_ignition.bootstrap_ign.id

    disk {
        volume_id = libvirt_volume.bootstrap_root_disk.id
    }

    network_interface {
        bridge = var.bridge_name
        mac = var.mac_addr
    }

    video {
        type = "virtio"
    }

    graphics {
        type = "vnc" 
        listen_type = "address"
    }

    console {
      type        = "pty"
      target_port = "0"
      target_type = "serial"
    }

    console {
      type        = "pty"
      target_type = "virtio"
      target_port = "1"
    }
}