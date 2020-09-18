#!/bin/bash

# --------------------------- color config ---------------------------
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
YE='\033[1;33m' # yellow
NC='\033[0m' # No Color
# --------------------------------------------------------------------

# ------------------------ dependency check --------------------------
check=`kubectl get storageclasses.storage.k8s.io | grep -q "(default)"`
if [ -z "$check" ]
then
  echo -e "[${LB}Info${NC}] storage class available"
else
  echo -e "[${YE}Warn${NC}] no storage class found, try to deploy localstorage provisioner"
  kubectl apply -f k8s/storage-class.yaml
fi
# --------------------------------------------------------------------

# -------------------------- deployment start ------------------------

echo -e "[${LB}Info${NC}] Install custom resource definitions and the operator with its RBAC rules"

# kubectl apply -f https://download.elastic.co/downloads/eck/1.2.1/all-in-one.yaml
kubectl apply -f all-in-one.yaml

kubectl config set-context --current --namespace=elastic-system

echo -e "[${LB}Info${NC}] deploy elasticsearch"
kubectl apply -f quickstart-es.yaml

echo -e "[${LB}Info${NC}] deploy kibana"
kubectl apply -f quickstart-kb.yaml

echo -e "[${LB}Info${NC}] deploy fluentd"
kubectl apply -f fluentd/fluentd-cm.yaml 
kubectl apply -f fluentd/fluentd-daemonset.yaml 

kubectl rollout status daemonset.apps/fluentd

# --------------------------------------------------------------------


# ---------------------- credentials and access ----------------------
elasticpw=`kubectl get secret quickstart-es-elastic-user -o go-template='{{.data.elastic | base64decode}}'`
echo -e "[${LB}Info${NC}] here are your kibana credentials. User is ${LB}elastic${NC}, Password ${LB}${elasticpw}${NC}"


echo -e "[${LB}Info${NC}] waiting for deployment of kibana and elasticsearch (takes a cuple of minutes)"
kubectl rollout status deployment/quickstart-kb

echo -e "Starting port foward for Kibana. Access at http://localhost:5601 press Ctrl-C when done"
kubectl port-forward service/quickstart-kb-http 5601
# --------------------------------------------------------------------

kubectl config set-context --current --namespace=default
