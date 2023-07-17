terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      # version = "0.6.11"
    }
  }
}

resource "libvirt_volume" "fcos_base_rootfs" {
    source = "file:///Users/borisassogba/Documents/devops/okd-world/okd-deployment/qemu-img/fedora-coreos-${var.fcos_version}-qemu.x86_64.raw"
    name = "fedora-coreos-${var.fcos_version}-qemu.x86_64.raw"
    pool = var.pool
    format = "raw"
}