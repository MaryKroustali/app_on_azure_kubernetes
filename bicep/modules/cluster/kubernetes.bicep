@description('Resource Name.')
param name string

@description('Resource Location.')
param location string = resourceGroup().location

@description('Id of the delegated subnet of type \'Microsoft.ContainerInstance/containerGroups\'')
param aks_snet_id string

@allowed([
  'Free'
  'Premium'
  'Standard'
])
@description('SKU tier of the cluster.')
param sku_tier string

@description('Number of worker node pools.')
@maxValue(10)
param worker_pools_count int

@description('Id of the log analytics workspace for monitorinbg the cluster.')
param log_id string

@description('Name of the resource group containing the Azure Container Registry.')
param acr_rg_name string


// A resource needs to have an identity in order to be assigned permissions
resource id 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'id-${name}'
  location: location
}

// Assign AcrPull permission to AKS cluster
module rbac './authorization.bicep' = {
  name: 'deploy-id-${name}-AcrPull'
  scope: resourceGroup(acr_rg_name)
  params: {
    principalId: id.properties.principalId
    role: '7f951dda-4ed3-4680-a7ca-43fe172d538d' // https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-05-01' = {
  name: name
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${id.id}': {}
    }
  }
  sku: {
    name: 'Base'
    tier: sku_tier
  }
  properties: {
    dnsPrefix: name
    agentPoolProfiles: [
      {
        name: 'master'    // Default node pool for cluster management
        vmSize: 'Standard_B2s_v2'
        osType: 'Linux'
        mode: 'System'
        count: 1
        type: 'VirtualMachineScaleSets'
        enableAutoScaling: false
        vnetSubnetID: aks_snet_id   // Node pool subnet
      }
    ]
    publicNetworkAccess: 'Disabled'   // Disable public access to the cluster
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
    nodeResourceGroup: 'MC_rg-${name}'  // Name for the managed resource group  (automatically created)
    securityProfile: {
      defender: {
        logAnalyticsWorkspaceResourceId: log_id  // Send cluster's logs to Log Analytics Workspace
        securityMonitoring: {
          enabled: true
        }
      }
    }
  }
}

// Worker node pools for the actual deployments
resource worker 'Microsoft.ContainerService/managedClusters/agentPools@2024-10-01' = [for i in range(0, worker_pools_count): {
  parent: aks
  name: 'worker${i+1}'
  properties: {
    vmSize: 'Standard_B2s_v2'
    osType: 'Linux'
    mode: 'User'
    count: 1
    enableAutoScaling: false
    type: 'VirtualMachineScaleSets'
    vnetSubnetID: aks_snet_id   // Node pool subnet
  }
}]
