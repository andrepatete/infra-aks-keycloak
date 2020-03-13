# Keycloak on AKS

Step-by-step configuration to deploy an HA Keycloak on an [Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/)
cluster.

### Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Helm](https://helm.sh/docs/using_helm/#installing-helm)

## Setup

`TODO: Architecture diagram`

### Preparation

```bash
$ az login

$ az aks get-credentials --resource-group IDM --name IDM-Dev
```

### Ingress controller using a static public IP address

#### Create a static public IP address

Get the resource group name of the AKS cluster:

```bash
$ az aks show --resource-group IDM --name IDM-Dev --query nodeResourceGroup -o tsv
```

Create a public IP address with the static allocation method in the AKS cluster resource group obtained in the previous step:

```bash
$ az network public-ip create --resource-group MC_IDM_IDM-Dev_eastus2 --name IDM-Dev-PublicIP --allocation-method static --query publicIp.ipAddress -o tsv
```

#### Deploy the `nginx-ingress` chart

Create a namespace for ingress resources:

```bash
$ kubectl create namespace idm
```

Use Helm to deploy an NGINX ingress controller:

```bash
$ helm init --upgrade

$ helm repo update 

$ helm install --name nginx-ingress stable/nginx-ingress \
    --namespace idm \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.service.loadBalancerIP="<public IP address created in the previous step>"
    --set controller.service.externalTrafficPolicy=Local # Enable client source IP preservation for requests to containers
```

Configure a DNS name:
 
Update the [fqdn.sh](fqdn.sh) script with the IP address of ingress controller and a unique name for the FQDN 
(Fully Qualified Domain Name), then run:

```bash
$ ./fqdn.sh
```

#### Install `cert-manager`

Install the `CustomResourceDefinition` resources separately:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
```

Create the namespace for `cert-manager`:

```bash
$ kubectl create namespace cert-manager
```

Label the cert-manager namespace to disable resource validation:

```bash
$ kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
```

Add the Jetstack Helm repository:

```bash
$ helm repo add jetstack https://charts.jetstack.io
```

Update local Helm chart repository cache:

```bash
$ helm repo update
```

Install the `cert-manager` Helm chart:

```bash
$ helm install \
    --name cert-manager \
    --namespace cert-manager \
    --version v0.8.0 \
    jetstack/cert-manager
```

#### Create a CA cluster issuer

`cert-manager` requires an Issuer or ClusterIssuer resource.

To create the `ClusterIssuer`, update [cluster-issuer.yaml](cluster-issuer.yaml) with FQDN and email, and then:

```bash
$ kubectl apply -f cluster-issuer.yaml
```

### StatefulSet Keycloak

#### Deploy the `codecentric/keycloak` chart

Add the codecentric Helm repository:

```bash
$ helm repo add codecentric https://codecentric.github.io/helm-charts

$ helm repo update
```

Install the chart using the [values.yaml](values.yaml) parameters:

```bash
$ helm install --name keycloak --namespace idm -f values.yaml codecentric/keycloak
```

##### *`git diff`*:

```bash
 keycloak:
-  replicas: 1
+  replicas: 2
 
   ## Password for the initial Keycloak admin user. Applicable only if existingSecret is not set.
   ## If not set, a random 10 characters password will be used
-  password: ""
+  password: "pass@123"
 
   ## Allows the specification of additional environment variables for Keycloak
   extraEnv: |
     - name: PROXY_ADDRESS_FORWARDING
       value: "true"
+    - name: KEYCLOAK_HTTP_PORT
+      value: "80"
+    - name: KEYCLOAK_HTTPS_PORT
+      value: "443"

   ## Ingress configuration.
   ## ref: https://kubernetes.io/docs/user-guide/ingress/
   ingress:
-    enabled: false
+    enabled: true
     path: /
 
-    annotations: {}
-      # kubernetes.io/ingress.class: nginx
-      # kubernetes.io/tls-acme: "true"
-      # ingress.kubernetes.io/affinity: cookie
+    annotations:
+      kubernetes.io/ingress.class: nginx
+      kubernetes.io/tls-acme: "true"
+      nginx.ingress.kubernetes.io/affinity: cookie
+      nginx.ingress.kubernetes.io/session-cookie-name: "AUTH_SESSION_ID"
+      certmanager.k8s.io/cluster-issuer: letsencrypt-prod
 
     ## List of hosts for the ingress
     hosts:
-      - keycloak.example.com
+      - idmdev.eastus2.cloudapp.azure.com
 
     ## TLS configuration
-    tls: []
-    # - hosts:
-    #     - keycloak.example.com
-    #   secretName: tls-keycloak
+    tls:
+    - hosts:
+      - idmdev.eastus2.cloudapp.azure.com
+      secretName: tls-keycloak

     # The database vendor. Can be either "postgres", "mysql", "mariadb", or "h2"
-    dbVendor: h2
+    dbVendor: postgres
 
     dbName: keycloak
-    dbHost: mykeycloak
+    dbHost: idmdev-pgsql.postgres.database.azure.com
     dbPort: 5432
-    dbUser: keycloak
+    dbUser: idmdev@idmdev-pgsql
 
     # Only used if no existing secret is specified. In this case a new secret is created
-    dbPassword: ""
+    dbPassword: "pass@123"
```

## References

[1] [https://github.com/codecentric/helm-charts/tree/master/charts/keycloak](https://github.com/codecentric/helm-charts/tree/master/charts/keycloak)

[2] [https://docs.microsoft.com/en-us/azure/aks/ingress-static-ip](https://docs.microsoft.com/en-us/azure/aks/ingress-static-ip)
