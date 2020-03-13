#! /bin/bash


echo "Realizar az Login"


# Prerequisito na maquina de implantação (az-cli, kubctl e Helm)
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
yum install azure-cli
az aks install-cli
wget https://get.helm.sh/helm-v2.14.1-linux-amd64.tar.gz
tar -zxvf helm-v2.*.tar.gz
mv linux-amd64/helm /usr/bin/helm


# Verificando versões do AKS disponiveis na região 
az aks get-versions --location eastus2 --output table
# atualizar o "K8SVERSION" em varoables.sh

## Variaveis Globais

source $PWD/variables.sh





# Criação Grupo Recursos 
az group create --name $RESOURCEGROUP --location $LOCATION

# Criação cluster AKS
az aks create \
    --resource-group $RESOURCEGROUP \
    --name $AKSNAME \
    --node-count $NODECOUNT \
    --enable-addons monitoring \
    --ssh-key-value $SSHKEY  \
    --subscription $SUBSCRIPTIONID \
    --enable-vmss \
    --enable-cluster-autoscaler \
    --min-count $MINCOUNT \
    --max-count $MAXCOUNT \
    --node-vm-size $VMSIZE \
    --admin-username $USERVM \
    --kubernetes-version $K8SVERSION \
    --service-principal $SERVICEPRINCIPAL \
    --client-secret $CLIENTSECRET
    

# Pegar Credenciais para o ~/.kube/config
az aks get-credentials --resource-group $RESOURCEGROUP --name $AKSNAME

# Acerto Permissão Dashboard
kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard

# Abrir o Browser
az aks browse \
--resource-group $RESOURCEGROUP \
--name $AKSNAME \
--subscription $SUBSCRIPTIONID


