//////// Application Resources ////////

targetScope = 'subscription'

param application string

var vnet_rg_name = 'rg-network-infra-${application}'
var snet_nodes_name = 'snet-pools-vnet-${application}'
var vnet_name = 'vnet-${application}'
var common_rg_name = 'rg-common-infra-${application}'
var log_name = 'log-${application}'

// Existing resources from previous deployments
resource vnet 'Microsoft.Network/virtualNetworks@2024-03-01' existing = {
  scope: resourceGroup(vnet_rg_name)
  name: vnet_name
}

resource snet_nodepools 'Microsoft.Network/virtualNetworks/subnets@2024-03-01' existing = {
  parent: vnet
  name: snet_nodes_name
}

resource log 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  scope: resourceGroup(common_rg_name)
  name: log_name
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-application-infra-${application}'
  location: 'northeurope'
}

module aks '../modules/cluster/kubernetes.bicep' = {
  scope: rg
  name: 'deploy-aks-${application}'
  params: {
    name: 'aks-${application}'
    aks_snet_id: snet_nodepools.id
    log_id: log.id
    sku_tier: 'Free'
    worker_pools_count: 1
  }
}

// Assign AcrPull permission to kubelet identity
module rbac '../modules/cluster/authorization.bicep' = {
  name: 'deploy-kubelet-AcrPull'
  scope: resourceGroup(common_rg_name) // resource group that contains the acr
  params: {
    principalId: aks.outputs.kubelet_id
    role: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
  }
}
