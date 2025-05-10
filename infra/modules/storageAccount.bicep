@description('The tags to associate with the resource')
param tags object

var uniqueName = uniqueString(resourceGroup().id, subscription().id)

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'storage${uniqueName}'
  location: resourceGroup().location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties:{
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    isHnsEnabled: true
    supportsHttpsTrafficOnly: true
  }  
}

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2024-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource storageAccounts_mdie020225_name_default_demo 'Microsoft.Storage/storageAccounts/queueServices/queues@2024-01-01' = {
  parent: queueServices
  name: 'demo'
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  name: guid(resourceGroup().id, deployer().objectId, 'Storage Queue Data Message Processor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '8a0f0c08-91a1-4084-bc3d-661d67233fed')
    principalId: deployer().objectId
  }
}

output storageAccountName string = storageAccount.name
