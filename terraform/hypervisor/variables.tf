# due to limitations with the libvirt provider (it does not properly
# populate the host variable for connections) we only support
# provisioning remote qemu+ssh libvirts :(
#
# 1) host: what host/ip you wish to remotely administer. defaults to localhost
# 2) user: what user to log in as. defaults to root.
# 3) ssh_private_key_path: path to the private ssh key that gets you passwordless access to the user.

# network resource you wish to deploy to.
variable "host" {
  type    = string
  default = "ocp.buzz.lab"
}

# user to authenticate to the resource as.
variable "user" {
  type    = string
  default = "root"
}

# path to private ssh key to allow passwordless access to the user account.
variable "ssh_private_key_path" {
  type    = string
  default = "~/.ssh/id_rsa"
}

# root disk size
variable "root_disk_size" {
  default = 60gb # 60 GiB
}

# Fedora CoreOS version. left blank because this is always set on the command line.
variable "coreos_version" {

}

##### WORKER CONFIGURATION ####

# How many MiB of ram to allocate for the workers
variable "worker_ram_size" {
  default = 16384
}

# How many vcpus to allocate for the workers
variable "worker_vcpu_count" {
  default = 8
}

# worker mac addresses for reservation purposes.
# A worker will be created for each MAC address specified here.
variable worker_mac_addrs {
  default = [
    "52:54:00:26:8c:76",
    "52:54:00:3d:71:8c",
    "52:54:00:c4:7d:86",
    "52:54:00:00:5a:70"
  ]
}

# # worker metadata disk size
# variable "worker_metadata_disk_size" {
#   default = 32212254720 # 30 GiB
# }

# Paths to data disks for the worker VMs.
# There should always be as many data disks as VMs.
# Therefore, this array should always be the same length
# as the worker_mac_addrs array.
# variable data_disks {
#   default = [
#     "/dev/sdc",
#     "/dev/sdd",
#     "/dev/sde"
#   ]
# }

##### MASTER CONFIGURATION ######

# number of masters to create on this host
variable "num_masters" {
  default = 3
}

# how many MiB of ram to allocate for the masters
variable "master_ram_size" {
  default = 12288
}

# how many vcpus to allocate for the masters
variable "master_vcpu_count" {
  default = 6
}

# mac addresses for the masters for reservations
variable master_mac_addrs {
  default = [
    "52:54:00:3e:b7:f7",
    "52:54:00:0b:55:46",
    "52:54:00:a8:99:b6"
  ]
}