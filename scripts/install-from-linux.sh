#!/usr/bin/env bash

CLUSTER_NAME=$1

GIT_TOKEN=$2

ACR_URL=$3
ACR_PRINCIPAL_ID=$4
ACR_PRINCIPAL_PASS=$5

DEVICE_CONNECTION_STRING=$6

# TODO: install the tools we need if they aren't already
# flux2
# kubeseal

# TODO: create directories for PV's (This will depend on single node or multi node install)

echo 'Creating gotk-components.yaml...'
flux install --version=latest --export > ./clusters/$CLUSTER_NAME/flux-system/gotk-components.yaml
echo 'Done'

echo 'Applying gotk-components.yaml...'
kubectl apply -f ./clusters/$CLUSTER_NAME/flux-system/gotk-components.yaml
echo 'Done'

echo 'Wait 1 minute to give it time to settle'
sleep 1m

echo 'Creating flux git source and linking to k8s-config-edge repo...'
flux create source git flux-system --git-implementation=libgit2 --url=https://sodalabs.visualstudio.com/SODA/_git/k8s-config-edge --branch=master --username=git --password=$GIT_TOKEN --interval=1m
echo 'Done'

echo 'Creating main flux kustomization...'
flux create kustomization flux-system --source=flux-system --path="./clusters/$CLUSTER_NAME" --prune=true --interval=10m
echo 'Done'

echo 'Creating gotk-sync.yaml'
flux export source git flux-system > ./clusters/$CLUSTER_NAME/flux-system/gotk-sync.yaml
flux export kustomization flux-system >> ./clusters/$CLUSTER_NAME/flux-system/gotk-sync.yaml
echo 'Done'

# TODO: 
# git add .
# git commit -m"Set up gotk for $CLUSTER_NAME"
# git push

echo 'Sleeping (5mins to go..)'
sleep 1m
echo 'Sleeping (4mins to go..)'
sleep 1m
echo 'Sleeping (3mins to go..)'
sleep 1m
echo 'Sleeping (2mins to go..)'
sleep 1m
echo 'Sleeping (1min to go..)'
sleep 1m

./install-setup-secrets $CLUSTER_NAME $ACR_URL $ACR_PRINCIPAL_ID $ACR_PRINCIPAL_PASS $DEVICE_CONNECTION_STRING

echo 'Install Done'

# TODO: git - commit and push