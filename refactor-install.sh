#!/bin/bash

set -euo pipefail

if [[ -z ${COREOS_VERSION+x} ]]; then
    COREOS_VERSION=$(curl -s https://builds.coreos.fedoraproject.org/streams/stable.json | jq -r '.architectures.x86_64.artifacts.qemu.release')
fi

echo "Bootstrapping cluster using Fedora CoreOS $COREOS_VERSION."

echo "$COREOS_VERSION" > .coreos_version


PROJECT_DIR="$PWD"
INSTALL_DIR="$PROJECT_DIR/config"
TERRAFORM_HOSTS_BASE_DIR="$PROJECT_DIR/terraform"

echo "Creating install configuration manifests..."

[[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
cp ./install-config.yaml "$INSTALL_DIR"

/usr/bin/openshift-install create manifests --dir="$INSTALL_DIR"

sed -i -e 's/mastersSchedulable: true/mastersSchedulable: false/' "$INSTALL_DIR/manifests/cluster-scheduler-02-config.yml"

/usr/bin/openshift-install create ignition-configs --dir="$INSTALL_DIR"


echo "Done. Now initializing cluster..."

for directory in hypervisor bootstrap ; do
    pushd "$TERRAFORM_HOSTS_BASE_DIR/$directory"
    [[ -d .terraform ]] || terraform init
    terraform apply --var "coreos_version=$COREOS_VERSION" --auto-approve
    popd
done

echo "Done."

echo "Now we wait for the bootstrap to complete."