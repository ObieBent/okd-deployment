# okd-deployment

## Prepare the environment for installing OKD 4.14
## On KVM Hypervisor 
All the below commands should be performed by using the root account. 

1. Install the KVM Hypervisor

For hosting nodes on this KVM/Libvirt Hypervisor, two partitions will be created as the following : 
- /srv/libvirt/ssd (for hosting masters nodes)
- /srv/libvirt/hdd (for hosting ISO images and workers nodes)

Install all the dependencies 
```sh 
dnf install qemu-kvm libvirt libvirt-python3 jq libguestfs-tools virt-install vim git curl wget firewalld NetworkManager-tui -y
```

Enable and start the service
```sh
systemctl enable libvirtd && systemctl start libvirtd && systemctl status libvirtd
systemctl enable firewalld && systemctl start firewalld && systemctl status firewalld
```


2. Create the **ocpnet** network in KVM
```sh
mkdir ~/ocp && cd ocp
cat <<EOF  | tee ocpnet.xml
<network>
  <name>ocpnet</name>
  <forward mode='nat' dev='enp4s0'/>
  <bridge name='ocpnet'/>
  <ip address='192.168.110.1' netmask='255.255.255.0'>
  </ip>
</network>
EOF
```

```sh
virsh net-define ocpnet.xml
virsh net-list --all
virsh net-autostart ocpnet
virsh net-start ocpnet
virsh net-list --all
virsh net-destroy default
virsh net-undefine default
systemctl restart libvirtd
```

3. Configure the network interfaces and the firewall 
```sh
public_nic="System $(route -n | grep UG | awk '{print $8}')"
nmcli connection modify ocpnet connection.zone libvirt
nmcli connection modify "$public_nic" connection.zone public
firewall-cmd --get-active-zones
firewall-cmd --zone=libvirt --add-masquerade --permanent
firewall-cmd --reload
firewall-cmd --list-all --zone=libvirt
```

4. Configure storage pools 
```sh
virsh pool-list --all
virsh pool-define-as ssd  dir - - - - "/srv/libvirt/ssd"
virsh pool-build ssd
virsh pool-start ssd
virsh pool-autostart ssd
virsh pool-info ssd
```

5. Download the Alma Linux 9.3 iso image to the dedicated pool on the host server. <br>
```sh
mkdir -p /srv/libvirt/ssd/iso && cd /srv/libvirt/ssd/iso
wget https://repo.almalinux.org/almalinux/9.3/isos/x86_64/AlmaLinux-9.3-x86_64-minimal.iso
```

## Helper Node
The Helper node will host the following services : 
- DNS Server
- Load Balancer
- Web Server
- DHCP
- NFSv4

This playbook helps set up the above services on the Helper node. These infrastructure services are required to install OpenShift 4. 

**Helper Node Installation**

Install an AlmaLinux9.2 server: <br>

```sh 
cd ~
git clone https://github.com/ObieBent/okd-deployment.git
cp okd-deployment/ks.cfg /
sh deployHelper.sh
```

The Kickstart file is used to automate the installation of the Helper node. 
After spining up the Helper node, you can login by using the below credentials: 
```sh
username: root
password: ocplab_1234
```
It is recommended to set up an another user account with the sudo rights to launch the playbook. 

**Using this playbook** 

Install Ansible with a regular user account: <br>
```sh
cd ~
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py --user
python3 -m pip install --user virtualenv
virtualenv -p python3 deploy
source deploy/bin/activate
python3 -m pip install --user ansible
pip3 install pyOpenSSL
```

Setup ansible before launching the playbook: <br>
```sh
cat <<EOF | tee ~/okd-deployment/ansible/ansible.cfg
[defaults]
inventory = inventory
command_warnings = False
filter_plugins = filter_plugins
host_key_checking = False
deprecation_warnings=False
retry_files = false
EOF

cat <<EOF | tee ~/okd-deployment/ansible/inventory
[all]
helper       ansible_host=192.168.110.9
EOF
```

Launch the playbook for installing the services: <br>
```sh
cd ~/okd-deployment/ansible
ansible-playbook tasks/main.yml -u <user> -b -l helper -v
```

**Install client and installer tools**

All the below commands should be performed by using the root account. <br>

```sh
# Kustomize
cd ~
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize /usr/bin/
kustomize version

# Terraform
curl https://releases.hashicorp.com/terraform/1.7.1/terraform_1.7.1_linux_amd64.zip -o terraform_1.7.1_linux_amd64.zip && unzip terraform_1.7.1_linux_amd64.zip
mv terraform /usr/bin/
terraform --version

# oc kubectl client
curl https://github.com/okd-project/okd/releases/download/4.14.0-0.okd-2024-01-06-084517/openshift-client-linux-4.14.0-0.okd-2024-01-06-084517.tar.gz -o openshift-client-linux-4.14.0-0.okd-2024-01-06-084517.tar.gz
tar -zxvf openshift-client-linux-4.14.0-0.okd-2024-01-06-084517.tar.gz
mv oc kubectl /usr/bin/
oc version
kubectl version --short

# openshift-install client
curl -L https://github.com/okd-project/okd/releases/download/4.14.0-0.okd-2024-01-06-084517/openshift-install-linux-4.14.0-0.okd-2024-01-06-084517.tar.gz -o openshift-install-linux-4.14.0-0.okd-2024-01-06-084517.tar.gz
tar -zxvf openshift-install-linux-4.14.0-0.okd-2024-01-06-084517.tar.gz
mv openshift-install /usr/bin/
openshift-install version

# Delete downloaded files
rm -f terraform_1.7.1_linux_amd64.zip
rm -f openshift-client-linux-4.14.0-0.okd-2024-01-06-084517.tar.gz
rm -f openshift-install-linux-4.14.0-0.okd-2024-01-06-084517.tar.gz
```

## OKD Deployment
**On Helper Node**

Spin up the following nodes: <br>
- Bootstrap
- Masters (03)
- Workers (04)

```sh 
sh refactor-install.sh
```

Monitor the bootstrap process: <br>
```sh
openshift-install --dir ~/okd-development/config wait-for bootstrap-complete --log-level=debug
```

Once bootstrapping is complete the bootstrap node can be removed. <br>
```sh
sh refactor-teardown-bootstrap.sh
```

Remove all references to the ocp-bootstrap host from the /etc/haproxy/haproxy.cfg file: <br>
```sh 
# Two entries
vim /etc/haproxy/haproxy.cfg
# Reload HAProxy
systemctl reload haproxy
```
