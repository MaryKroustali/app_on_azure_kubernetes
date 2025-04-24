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

resource aks 'Microsoft.ContainerService/managedClusters@2023-05-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: sku_tier
  }
  properties: {
    // dnsPrefix: dnsPrefix
    // networkProfile: {
    //   networkPlugin: 'kubenet'
    //   networkPolicy: 'calico'
    //   loadBalancerSku: 'Standard'
    //   outboundType: 'userDefinedRouting'
    // }
    apiServerAccessProfile: {
      enablePrivateCluster: true   // Disable public access to the cluster
    }
    // securityProfile: {
    //   defender: {
    //     logAnalyticsWorkspaceResourceId: log_id  // Send cluster's logs to Log Analytics Workspace
    //     securityMonitoring: {
    //       enabled: true
    //     }
    //   }
    // }
  }
}


// Node Pools

// Default node pool for cluster management
resource master 'Microsoft.ContainerService/managedClusters/agentPools@2024-10-01' = {
  parent: aks
  name: 'master'
  properties: {
    vmSize: 'Standard_B1ms'
    osType: 'Linux'
    mode: 'System'
    count: 1
    type: 'VirtualMachineScaleSets'
    enableAutoScaling: false
    vnetSubnetID: aks_snet_id   // Node pool subnet
  }
}

// Worker node pools for the actual deployments
resource worker 'Microsoft.ContainerService/managedClusters/agentPools@2024-10-01' = [for i in range(0, worker_pools_count): {
  parent: aks
  name: 'worker${i}'
  properties: {
    vmSize: 'Standard_B1ms'
    osType: 'Linux'
    mode: 'User'
    count: 1
    enableAutoScaling: false
    type: 'VirtualMachineScaleSets'
    vnetSubnetID: aks_snet_id   // Node pool subnet
  }
}]

