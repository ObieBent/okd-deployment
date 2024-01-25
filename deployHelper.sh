#!/bin/bash
set -e -u -o pipefail

_log() {
    local level=$1; shift
    echo -e "$level: $@"
}

info() {
    _log "\nINFO\n" "$@"
}

# Disk creation
helper_disk_creation() {
    info "Creating Helper disk"
    qemu-img create -o preallocation=metadata -f qcow2 /srv/libvirt/hdd/helper.qcow2 450G
    sleep 15
}


# Helper Installation
helper_installation() {
    info "Deploying Alma Linux 8.7 on the Helper server"
    virt-install \
    --network network:ocpnet \
    --name helper \
    --os-type=linux \
    --location /srv/libvirt/hdd/iso/AlmaLinux-9.3-x86_64-minimal.iso \
    --ram=8192 \
    --os-variant=almalinux8 \
    --vcpus=4 \
    --disk /srv/libvirt/hdd/helper.qcow2 --boot hd,menu=on\
    --nographics \
    --initrd-inject /ks.cfg \
    --extra-args "inst.ks=file:/ks.cfg console=tty0 console=ttyS0,115200n8"
}

helper_disk_creation
helper_installation