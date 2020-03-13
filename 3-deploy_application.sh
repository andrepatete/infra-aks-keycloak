#!/bin/bash

source $PWD/variables.sh

# Create Plublic IP
RESOURCEGROUPAKS=$(az aks show --resource-group $RESOURCEGROUP --name $AKSNAME --query nodeResourceGroup -o tsv)

az network public-ip create --resource-group $RESOURCEGROUPAKS --name $PUBLUCIPNAME --allocation-method static --query publicIp.ipAddress -o tsv

AKSPublicIP=$(az network public-ip list -g $RESOURCEGROUPAKS --subscription $SUBSCRIPTIONID --query "[?name=='$PUBLUCIPNAME']"|grep ipAddress|awk '{print $2}'|cut -c2-|  sed 's/",//g')


# Deploy Ingress Controler 
helm install --name nginx-ingress stable/nginx-ingress \
  --namespace $NAMESPACE \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
  --set controller.service.loadBalancerIP="$AKSPublicIP" \
  --set controller.service.externalTrafficPolicy=Local # Enable client source IP preservation for requests to containers


# Get the resource-id of the public ip
PUBLICIPID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$AKSPublicIP')].[id]" --output tsv)


# Update public ip address with DNS name
az network public-ip update --ids $PUBLICIPID --dns-name $DNSNAME


## Install cert-manager

kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

kubectl create namespace cert-manager

kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

helm repo add jetstack https://charts.jetstack.io

helm repo update

helm install \
    --name cert-manager \
    --namespace cert-manager \
    --version v0.8.0 \
    jetstack/cert-manager

kubectl apply -f cluster-issuer.yaml



# Create a CA cluster issuer

kubectl apply -f keycloak/cluster-issuer.yaml



# Deploy Keycloak

helm repo add codecentric https://codecentric.github.io/helm-charts

helm repo update

helm install --name keycloak --namespace $NAMESPACE -f keycloak/values.yaml codecentric/keycloak



