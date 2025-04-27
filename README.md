# App on Azure Kubernetes Service
This repository uses container image from [containerized_app_on_azure](https://github.com/MaryKroustali/containerized_app_on_azure)'s packages. This time it is hosted on Azure Kubernetes Service (AKS) to overcome[limitations](https://github.com/MaryKroustali/containerized_app_on_azure?tab=readme-ov-file#limitations) present on Azure light-weight container services.

## Architecture

The following architecture uses AKS.



### Managed Resource Group

The aks as infrastructure as a service solution creates a second resource group named `MC_rg-aks-record-store` with all the resources needed for the aks eg Virtual Machine Scale Sets working as Master and Worker node pools. For a detailed description on how kubernetes work on Azure see [Core concepts for AKS](https://learn.microsoft.com/en-us/azure/aks/core-aks-concepts).

#### Authorization to the ACR

In order for the AKS to be authorized to pull images from the ACR for its pods the kubelet identity located in the AKS managed resource group is assigned the `ACRPull` role.

## Kubernetes

## Github Workflows
Workflows used for this setup are similar to [containerized_app_on_azure](https://github.com/MaryKroustali/containerized_app_on_azure/blob/main/README.md#github-actions) repository:
- `Deploy Infrastructure`: Creates all the necessary Azure resources.
- `Push Image to ACR`: Tags and pushes the Docker image to ACR, using the Linux Github Runner.
- `Import Data to Database`: Importing data into the SQL database, using the Windows Github Runner.
- `Deploy to AKS`: Applies the necessary manifest files to create the application and ingress nginx kubernetes resources.

[![Deploy Infrastructure](https://github.com/MaryKroustali/kubernetes_on_azure/actions/workflows/deploy_infra.yaml/badge.svg)](https://github.com/MaryKroustali/kubernetes_on_azure/actions/workflows/deploy_infra.yaml)
[![Push Image to ACR](https://github.com/MaryKroustali/kubernetes_on_azure/actions/workflows/push_to_registry.yaml/badge.svg)](https://github.com/MaryKroustali/kubernetes_on_azure/actions/workflows/push_to_registry.yaml)
[![Import Data to Database](https://github.com/MaryKroustali/kubernetes_on_azure/actions/workflows/import_db_data.yaml/badge.svg)](https://github.com/MaryKroustali/kubernetes_on_azure/actions/workflows/import_db_data.yaml)
[![AKS deployments](https://github.com/MaryKroustali/kubernetes_on_azure/actions/workflows/deploy_to_aks.yaml/badge.svg)](https://github.com/MaryKroustali/kubernetes_on_azure/actions/workflows/deploy_to_aks.yaml)

# Next Steps
[app_on_aks_gitops](https://github.com/MaryKroustali/app_on_aks_gitops): Managing an application deployment on Azure Kubernetes Service using GitOps (ArgoCD).