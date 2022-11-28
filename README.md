# HELM AKS ELK Cluster

This repo might serve as a starting point to deploy an full ELK cluster in a AKS by using an HELM package.

## Disclaimer

The deployment might not be production ready and it might not contain security patches. Kindly review the template before using it in Prod.

## Copyright

<a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/">Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License</a>.
# How-to-use-it

## 1) First steps

As a first thing - you should have an Azure Account setup and a subscription ready to be used.

> Make sure that you are selecting the correct Subscription by running the following AzCli command "az account show"

Once you have the subscription sorted out, just run the **init.ps1** script. This will create an RG which it will contain the storage account used by Terraform to store the state of the plans that we will be executing.

> Open init.ps1 and change the variables as you need before running it. Changing the init.ps1 might also require changes on the "backend" block of each provider.tf

After that make sure to have [Helm](https://helm.sh/docs/intro/install/) and [Kubectl](https://kubernetes.io/docs/tasks/tools/) installed on your PC. 

## 2) Deploy an AKS cluster

An AKS cluster needs to be deployed. The terraform template provided will deploy an AKS in a private VNET and it will use an [AppGateway](https://learn.microsoft.com/en-us/azure/application-gateway/overview) to provide public IPs to the cluster by an [Ingress](https://learn.microsoft.com/en-us/azure/application-gateway/ingress-controller-overview).

- Open a cmd or powershell.
- cd into the **AKS_Cluster** folder.
- Terraform **init**
- Terraform **apply -var="name_prefix=pick_your_prefix"**

## 3) Install ELK Helm Chart

We will not use Helm to install the ELK cluster.

- Open a cmd or powershell.
- cd into the **ELK** folder.
- Review the values on **values.yaml**.
- Run **helm dependency build**.
- Get the AKS credentials from the AKS dashboard on the Azure portal. This will setup connection for the Kubectl.
- Run **helm install [name_of_my_release] .**.

## 4) Review Changes

To confirm that the installation was successful, run the following command:

- Open a cmd or powershell.
- **kubectl get pod,svc,ingress,sts -o wide**

The ingress should have a public IP assigned to it by the Application Gateway and you should be able to open it in a browser.