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


flux install --version=latest --export > ./clusters/$CLUSTER_NAME/flux-system/gotk-components.yaml
kubectl apply -f ./clusters/$CLUSTER_NAME/flux-system/gotk-components.yaml
echo 'Wait 1 minute to give it time to run'
sleep 1m

flux2 create source git flux-system --git-implementation=libgit2 --url=https://sodalabs.visualstudio.com/SODA/_git/k8s-config-edge --branch=master --username=git --password=$GIT_TOKEN --interval=1m
flux2 create kustomization flux-system --source=flux-system --path="./clusters/$CLUSTER_NAME" --prune=true --interval=10m

# temporary hack 
echo 'Temporary hack to get around windows bug'
echo 'Replace the incorrect \ on cluster\$CLUSTER_NAME with cluster/$CLUSTER_NAME'
kubectl edit kustomization.kustomize.toolkit.fluxcd.io/flux-system -n flux-system

# get the public cert for the sealed secret controller
kubeseal --fetch-cert --controller-name=sealed-secrets --controller-namespace=flux-system > ./clusters/$CLUSTER_NAME/pub-sealed-secrets.pem

# create the image-pull secret
kubectl create secret docker-registry acr-secret --namespace kafka-streams --docker-server=$ACR_URL --docker-username=$ACR_PRINCIPAL_ID --docker-password=$ACR_PRINCIPAL_PASS --dry-run=client -o yaml > plain-acr-pull-secret.yaml
kubeseal --format=yaml --cert=./clusters/$CLUSTER_NAME/pub-sealed-secrets.pem < plain-acr-pull-secret.yaml > ./apps/$CLUSTER_NAME/sealed-acr-pull-secret-patch.yaml
rm plain-acr-pull-secret.yaml

# create the edge device connection string secret
kubectl create secret generic device-connection-string-secret --from-literal=device-connection-string="$DEVICE_CONNECTION_STRING" --namespace iotedge --dry-run=client -o yaml > plain-device-connection-string-secret.yaml
kubeseal --format=yaml --cert=./clusters/$CLUSTER_NAME/pub-sealed-secrets.pem < plain-device-connection-string-secret.yaml > ./apps/$CLUSTER_NAME/sealed-device-connection-string-secret-patch.yaml 
rm plain-device-connection-string-secret.yaml


flux2 export source git flux-system > ./clusters/$CLUSTER_NAME/flux-system/gotk-sync.yaml
flux2 export kustomization flux-system >> ./clusters/$CLUSTER_NAME/flux-system/gotk-sync.yaml

# TODO: git - commit and push