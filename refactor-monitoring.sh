#!/bin/bash 

set -euo pipefail

PROJECT_DIR="$PWD"
MONITORING_DIR="$PROJECT_DIR/monitoring"

OPENSHIFT_INSTALL_RELEASE="$(curl -s https://api.github.com/repos/okd-project/okd/releases | jq -r '.[].tag_name' | grep ^4.14 | head -n1)"
OPENSHIFT_INSTALL="$PROJECT_DIR/openshift-install-${OPENSHIFT_INSTALL_RELEASE}"

#### AUTOMATICALLY APPROVE WORKER CSRS #########

echo "Approving worker CSRs..."

while [[ $(oc get csr | grep -cF kubelet-serving) -lt 7 ]] || [[ $(oc get --no-headers nodes | grep -cF Ready) -lt 7 ]]; do
    oc get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs --no-run-if-empty oc adm certificate approve
    sleep 1
done

echo "Done."

###### END AUTOMATICALLY APPROVE WORKER CSRS ########

##### CONFIGURE MONITORING #####

echo "Configuring monitoring..."
oc apply -f "$MONITORING_DIR/configmap.yaml"
echo "Done."

##### CONFIGURE MONITORING DONE #####

#### DISBALE SAMPLES OPERATOR BEGIN ######

echo "Disabling samples operator..."
oc patch configs.samples.operator.openshift.io cluster --type merge --patch '{"spec": {"managementState": "Removed"}}'
echo "Done."

#### DISABLE SAMPLES OPERATOR END #####

"${OPENSHIFT_INSTALL}" --dir=config wait-for install-complete --log-level=debug