
###### Cluster creation steps and initial settings at ./1-create_cluste_prod.sh.
###### Note: Run the commands step by step, the script is not yet ready to run at once.
###### These steps are only for installing the cluster.

###### Steps to create the volume to be used (Azure File share) ./2-create_azure_fileshare_volumes.sh.
###### Note: Run the commands step by step, the script is not yet ready to run at once.
###### These steps are only for installing the cluster.

###### Steps to deploy the application (KEycloak) via Helm ./3-deploy_application.sh.
###### Note: Run the commands step by step, the script is not yet ready to run at once.
###### These steps are only for installing the cluster.



# Cluster Access.

### Set environment variables.

```
SUBSCRIPTIONID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
RESOURCEGROUP="IDM"
ENVIRONMENT="Prod"
AKSNAME="$RESOURCEGROUP-$ENVIRONMENT"
```

### Set Subscription.
```
az login
az account set --subscription $SUBSCRIPTIONID
```


### Add Kubernetes Credentials to ~/.kube/config.
```
az aks get-credentials --resource-group $RESOUCEGROUPE --name $AKSNAME
```


### Open the Browser.
```
az aks browse --resource-group $RESOUCEGROUPE --name $AKSNAME --subscription $SUBSCRIPTIONID
```


### Requirement: az-cli, kubctl, Helm e jq.
#### To RedHat, CentOS or Fedora.
```
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
yum install azure-cli jq
az aks install-cli
wget https://get.helm.sh/helm-v2.14.1-linux-amd64.tar.gz
tar -zxvf helm-v2.*.tar.gz
mv linux-amd64/helm /usr/bin/helm
```


### Commands for switching between clusters and verifying information.
```
kubectl cluster-info
kubectl config current-context
kubectl config get-contexts
kubectl config use-context $AKSNAME
```







### References:
 * https://istio.io/docs/setup/install/helm/#option-2-install-with-helm-and-tiller-via-helm-install
 * https://helm.sh/docs/using_helm/#from-the-binary-releases
 * https://docs.microsoft.com/pt-br/azure/aks/ingress-static-ip
 * https://docs.cert-manager.io/en/latest/getting-started/install/kubernetes.html
 * https://docs.microsoft.com/pt-br/azure/aks/azure-files-volume
 * https://github.com/codecentric/helm-charts/tree/master/charts/keycloak
 * http://10.55.200.102:7990/projects/IDM/repos/keycloak-aks/browse


