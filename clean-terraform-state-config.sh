#!/bin/bash
set -euo pipefail

# Clean directories and files generated by Terraform
echo " Clean directories and files generated by Terraform ... "

if [[ -d "$PWD/terraform/bootstrap/.terraform" && -f "$PWD/terraform/bootstrap/terraform.tfstate*" ]]; then
	rm -rf /root/okd-deployment/terraform/bootstrap/.terraform*
	rm -rf /root/okd-deployment/terraform/bootstrap/terraform.tfstate*
fi

if [[ -d "$PWD/terraform/hypervisor/.terraform" && -f "$PWD/terraform/hypervisor/terraform.tfstate*" ]]; then
	rm -rf /root/okd-deployment/terraform/hypervisor/.terraform*
	rm -rf /root/okd-deployment/terraform/hypervisor/terraform.tfstate*
fi

# Clean ignition, .coreos_version and authentication files
echo " Cleaning ignition and authentication files ... "

if [[ -d "$PWD/config" && -f "$PWD/.coreos_version" ]]; then
	rm -rf "$PWD/config"
	rm -f "$PWD/.coreos_version"
fi