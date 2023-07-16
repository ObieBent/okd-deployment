#!/bin/bash

# Deploys the cluster. After setting the necessary inline configuration variables
# in the script below, you can run the script like so:
# ```sh
# $ ROOK_TAG="v1.5.9" ./deploy.sh
# ```
# This will deploy a cluster using the latest stable OKD release and the latest version
# of FCOS. It will deploy Rook v1.5.9 into the cluster. You can optionally specify a
# version of FCOS to deploy using the COREOS_VERSION environment variable, and/or a specific
# version of OKD with the OPENSHIFT_INSTALL_RELEASE environment variable.

set -euo pipefail

# DEBUG
#set -x

##### INLINE CONFIGURATION VARIABLES ####
# Set these up to match your enviroment before you run the script.
# Note that the cluster subdomain has to match whatever you set up for
# DNS.

CLUSTER_SUBDOMAIN="cluster-okd.buzz.lab"
HYPERVISOR="localhost"
# HYPERVISOR_1="hv1.okd.example.com"
# HYPERVISOR_2="hv2.okd.example.com"
# HYPERVISOR_3="hv3.okd.example.com"

##### END INLINE CONFIGURATION VARIABLES ####

# check dependencies
for cmd in 'ansible-playbook' 'kustomize' 'curl' 'jq' 'mktemp' 'oc' 'tar' 'mkdir' 'cp' 'mv' 'rm' 'sed' 'terraform' 'ssh' 'openssl'; do
    if ! $(command -v $cmd &>/dev/null); then
        echo "This script requires the $cmd binary to be present in the system's PATH. Please install it before continuing."
        exit 1
    fi
done

if [[ -z ${OPENSHIFT_INSTALL_RELEASE+x} ]]; then
    # get the latest okd release from the repo
    OPENSHIFT_INSTALL_RELEASE="$(curl -s https://api.github.com/repos/okd-project/okd/releases | jq -r '.[].tag_name' | grep ^4.12 | head -n1)"
    OKD_DOWNLOAD_URL="$(curl -s https://api.github.com/repos/okd-project/okd/releases | jq -r '.[].assets[] | select(.name | contains("openshift-install-linux-$OPENSHIFT_INSTALL_RELEASE")) | .browser_download_url')"
fi

echo "Using OKD release $OPENSHIFT_INSTALL_RELEASE to bring up cluster."

if [[ -z ${COREOS_VERSION+x} ]]; then
    COREOS_VERSION=$(curl -s https://builds.coreos.fedoraproject.org/streams/stable.json | jq -r '.architectures.x86_64.artifacts.qemu.release')
fi

echo "Bootstrapping cluster using Fedora CoreOS $COREOS_VERSION."

echo "$COREOS_VERSION" > .coreos_version

PROJECT_DIR="$PWD"
INSTALL_DIR="$PROJECT_DIR/config"
MONITORING_DIR="$PROJECT_DIR/monitoring"
KUBECONFIG_PATH="$INSTALL_DIR/auth/kubeconfig"
TERRAFORM_HOSTS_BASE_DIR="$PROJECT_DIR/terraform"

OPENSHIFT_INSTALL="$PROJECT_DIR/openshift-install-${OPENSHIFT_INSTALL_RELEASE}"

get_installer() {
    TEMPDIR=$(mktemp -d)
    pushd $TEMPDIR
    if [[ -z ${OKD_DOWNLOAD_URL+x} ]]; then
        oc adm release extract --command 'openshift-install' "quay.io/openshift/okd:$OPENSHIFT_INSTALL_RELEASE" || \
        oc adm release extract --command 'openshift-install' "registry.svc.ci.openshift.org/origin/release:$OPENSHIFT_INSTALL_RELEASE"
    else
        echo "Downloading OKD release $OPENSHIFT_INSTALL_RELEASE..."
        curl -LO $OKD_DOWNLOAD_URL
        tar -xf "openshift-install-linux-$OPENSHIFT_INSTALL_RELEASE.tar.gz"
    fi
    popd
    mv "$TEMPDIR/openshift-install" ${OPENSHIFT_INSTALL}
    rm -rf $TEMPDIR
}

echo "Creating install configuration manifests..."

[[ -f "$OPENSHIFT_INSTALL" ]] || get_installer
[[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"

mkdir -p "$INSTALL_DIR"
cp ./install-config.yaml "$INSTALL_DIR"

"${OPENSHIFT_INSTALL}" create manifests --dir="$INSTALL_DIR"

sed -i -e 's/mastersSchedulable: true/mastersSchedulable: false/' "$INSTALL_DIR/manifests/cluster-scheduler-02-config.yml"

"${OPENSHIFT_INSTALL}" create ignition-configs --dir="$INSTALL_DIR"

echo "Done. Now initializing cluster..."

ansible-playbook  --user root ansible/main.yml --extra-vars "coreos_version=${COREOS_VERSION} -k -vv -l localhost"

# we do the bootstrap last so that all the actual infra can start bootstrapping ASAP
for directory in hypervisor bootstrap; do
    pushd "$TERRAFORM_HOSTS_BASE_DIR/$directory"
    [[ -d .terraform ]] || terraform init
    terraform apply --var "coreos_version=$COREOS_VERSION" --auto-approve
    popd
done

echo "Done."

echo "Now we wait for the bootstrap to complete."

"${OPENSHIFT_INSTALL}" --dir=config wait-for bootstrap-complete --log-level=debug