output "bootstrap_rootfs" {
    value = libvirt_volume.bootstrap_root_disk.id
}