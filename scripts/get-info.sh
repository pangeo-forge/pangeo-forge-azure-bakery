#!/bin/bash

function cleanupK8s {
  echo "Killing Kubernetes tunnel"
  pkill -P $$
}

ROOT=$(pwd)
echo "------------------------------------------"
echo "       Pangeo Forge - GCE bakery"
echo "   ----  FLOW RUN INFO FINDER ----"
echo "------------------------------------------"
echo "- Running prepare script"
source "$ROOT/scripts/prepare.sh" "$ROOT"

echo "- Running kubernetes connector script"
$ROOT/scripts/k8s-connect.sh

echo "- Setup exit trap"
trap cleanupK8s EXIT

echo "- Gathering data"
mapfile -t < <(kubectl logs -n "$BAKERY_NAMESPACE" deployment/prefect-agent | sed -rn "s/\[([0-9]+-[0-9]+-[0-9]+) ([0-9]+:[0-9]+:[0-9]+).* agent \| Completed deployment of flow run (.*)/\1@\2-\3/p")
if [ ${#MAPFILE[@]} == 0 ]; then
  echo "No flow runs have been performed on this agent yet"
  exit 1
fi
PS3="Select a run from the list:"
select run in "${MAPFILE[@]}"
do
    echo "Selected character: $run"
    echo "Selected number: $REPLY"
    break
done
ID=$(echo $run | sed -rn "s/([0-9]+-[0-9]+-[0-9]+)@([0-9]+:[0-9]+:[0-9]+)-(.*)/\3/p")
echo "---------------------------------------------------------------------------------"
echo "Jobs for flow run $run"
echo "---------------------------------------------------------------------------------"
JOB_ID=$(kubectl get jobs -n "$BAKERY_NAMESPACE" --selector=prefect.io/flow_run_id=$ID -o jsonpath='{.items[*].metadata.name}')
echo $JOB_ID
echo "---------------------------------------------------------------------------------"
echo "Dask clusters spun up from job $JOB_ID for flow run $ID"
echo "---------------------------------------------------------------------------------"
LOGS=$(kubectl logs -n "$BAKERY_NAMESPACE" jobs/$JOB_ID)
DASK_CLUSTER=$(echo $LOGS | sed -rn "s/.* The Dask dashboard is available at http:\/\/(.*)."$BAKERY_NAMESPACE".*/\1/p")
if [ -z $DASK_CLUSTER ]; then
  echo "No dask clusters have been made by this flow yet"
  exit 2
fi
echo Cluster name is $DASK_CLUSTER
PORT=$(echo $LOGS | sed -rn "s/.* The Dask dashboard is available at http:\/\/.*."$BAKERY_NAMESPACE"\:([0-9]+).*/\1/p")
echo PORT IS $PORT
kubectl port-forward -n $BAKERY_NAMESPACE svc/$DASK_CLUSTER 8787 > /dev/null 2>&1 &
K8S_PID=$!
echo "Dask cluster dashboard is now available at http://localhost:8787 for the duration of the run"
echo "---------------------------------------------------------------------------------"
echo "Your loki search terms are:"
echo "---------------------------------------------------------------------------------"
echo "{dask_org_cluster_name=\"$DASK_CLUSTER\",dask_org_component=\"worker\"}"
echo "{dask_org_cluster_name=\"$DASK_CLUSTER\",dask_org_component=\"scheduler\"}"
echo "---------------------------------------------------------------------------------"
read  -n 1 -p "Press ENTER/Return to exit. (Will also close the Kubernetes Dask tunnel)" dump