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
  default = "okd.bomar.bme.lab"
}

# user to authenticate to the resource as.
variable "user" {
  type    = string
  default = "borisassogba"
}

# path to private ssh key to allow passwordless access to the user account.
# variable "ssh_private_key_path" {
#   type    = string
#   default = "~/.ssh/id_rsa"
# }

# mac address for bootstrap vm for reservation
variable bootstrap_mac_addr {
  default = "52:54:00:f3:cd:dd"
}

# bootstrap root disk size
variable bootstrap_root_disk_size {
  default = 42949672960 # 40 GiB (any less and the bootstrap will fail due to running out of tmpfs space)
}

# Fedora CoreOS version. left blank because this is always set by the tfvars.
variable "coreos_version" {

}