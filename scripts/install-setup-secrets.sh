#!/usr/bin/env bash

CLUSTER_NAME=$1

ACR_URL=$2
ACR_PRINCIPAL_ID=$3
ACR_PRINCIPAL_PASS=$4

DEVICE_CONNECTION_STRING=$5

echo 'Fetching the public cert for the sealed secret controller...'
kubeseal --fetch-cert --controller-name=sealed-secrets --controller-namespace=flux-system > ./clusters/$CLUSTER_NAME/pub-sealed-secrets.pem
echo 'Done'

echo 'Creating the image-pull secret...'
kubectl create secret docker-registry acr-secret --namespace kafka-streams --docker-server=$ACR_URL --docker-username=$ACR_PRINCIPAL_ID --docker-password=$ACR_PRINCIPAL_PASS --dry-run=client -o yaml > plain-acr-pull-secret.yaml
kubeseal --format=yaml --cert=./clusters/$CLUSTER_NAME/pub-sealed-secrets.pem < plain-acr-pull-secret.yaml > ./apps/$CLUSTER_NAME/sealed-acr-pull-secret-patch.yaml
rm plain-acr-pull-secret.yaml
echo 'Done'

echo 'Creating the edge device connection string secret'
kubectl create secret generic device-connection-string-secret --from-literal=device-connection-string="$DEVICE_CONNECTION_STRING" --namespace iotedge --dry-run=client -o yaml > plain-device-connection-string-secret.yaml
kubeseal --format=yaml --cert=./clusters/$CLUSTER_NAME/pub-sealed-secrets.pem < plain-device-connection-string-secret.yaml > ./apps/$CLUSTER_NAME/sealed-device-connection-string-secret-patch.yaml 
rm plain-device-connection-string-secret.yaml
echo 'Done'

echo 'Setup secrets Done'

# TODO: git - commit and push