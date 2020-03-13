#!/bin/bash

# Change these four parameters as needed for your own environment
source $PWD/variables.sh


# Create Namespace
kubectl create namespace $NAMESPACE

# Create a resource group (Opitional)
#az group create --name $RESOURCEGROUP --location $LOCATION

# Create a storage account
az storage account create -n $STORAGEACCOUNTNAME -g $RESOURCEGROUP -l $LOCATION --sku Standard_LRS

# Export the connection string as an environment variable, this is used when creating the Azure file share
export AZURE_STORAGE_CONNECTION_STRING=`az storage account show-connection-string -n $STORAGEACCOUNTNAME -g $RESOURCEGROUP -o tsv`

# Create the file share
az storage share create -n $AKSSHARENAME --connection-string $AZURE_STORAGE_CONNECTION_STRING

# Get storage account key
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCEGROUP --account-name $STORAGEACCOUNTNAME --query "[0].value" -o tsv)

# Echo storage account name and key
echo Storage account name: $STORAGEACCOUNTNAME
echo Storage account key: $STORAGE_KEY



# Create Kubernetes secret
kubectl create secret generic azure-secret -n $NAMESPACE --from-literal=azurestorageaccountname=$STORAGEACCOUNTNAME --from-literal=azurestorageaccountkey=$STORAGE_KEY

sleep 30

# Create PV and PVC
kubectl apply -f ./PersistentVolume.yaml
kubectl apply -f ./PersistentVolumeClaim.yaml


