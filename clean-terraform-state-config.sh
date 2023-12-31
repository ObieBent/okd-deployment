#!/bin/bash
set -euo pipefail

# Clean directories and files generated by Terraform
echo " Clean directories and files generated by Terraform ... "

if [[ -d $PWD/terraform/bootstrap/.terraform || -n "$(find $PWD/terraform/bootstrap -name 'terraform.tfstate*' -print -quit)" ]]; then
	rm -rf $PWD/terraform/bootstrap/.terraform*
	rm -f $PWD/terraform/bootstrap/terraform.tfstate*
fi

if [[ -d $PWD/terraform/hypervisor/.terraform  || -n "$(find $PWD/terraform/hypervisor -name 'terraform.tfstate*' -print -quit)" ]]; then
	rm -rf $PWD/terraform/hypervisor/.terraform*
	rm -f $PWD/terraform/hypervisor/terraform.tfstate*
fi

# Clean ignition, .coreos_version and authentication files
echo " Cleaning ignition and authentication files ... "

if [[ -d "$PWD/config" && -f "$PWD/.coreos_version" ]]; then
	rm -rf $PWD/config
	rm -f $PWD/.coreos_version
fi