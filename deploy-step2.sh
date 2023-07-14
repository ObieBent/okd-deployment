#!/bin/bash

set -euo pipefail

PROJECT_DIR="$PWD"
INSTALL_DIR="$PROJECT_DIR/config"
KUBECONFIG_PATH="$INSTALL_DIR/auth/kubeconfig"
TERRAFORM_HOSTS_BASE_DIR="$PROJECT_DIR/terraform"

OPENSHIFT_INSTALL="$PROJECT_DIR/openshift-install-${OPENSHIFT_INSTALL_RELEASE}"

if [[ -z ${COREOS_VERSION+x} ]]; then
    COREOS_VERSION=$(curl -s https://builds.coreos.fedoraproject.org/streams/stable.json | jq -r '.architectures.x86_64.artifacts.qemu.release')
fi

echo "The cluster is provisionally available. Removing the bootstrap VM..."

pushd "$TERRAFORM_HOSTS_BASE_DIR/bootstrap"
terraform destroy --var "coreos_version=$COREOS_VERSION" --auto-approve
popd

echo "Done."

export KUBECONFIG="$KUBECONFIG_PATH"

echo "Waiting for API server to come up fully..."
until oc wait --for=condition=Degraded=False clusteroperator kube-apiserver; do
    echo "Still waiting..."
done

until oc wait --for=condition=Progressing=False clusteroperator kube-apiserver; do
    echo "Still waiting..."
done

until oc wait --for=condition=Available=True clusteroperator kube-apiserver; do
    echo "Still waiting..."
done

echo "Done."