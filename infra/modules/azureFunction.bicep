@description('The tags to associate with the resource')
param tags object

param storageAccountName string
param appConfigName string

var uniqueName = uniqueString(resourceGroup().id, subscription().id)

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName
}

resource servicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'serviceplan-${uniqueName}'
  location: resourceGroup().location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {
    reserved: false
  }
  kind: 'functionapp'
}

resource createdAppConfiguration 'Microsoft.AppConfiguration/configurationStores@2024-05-01' existing = {
  name: appConfigName
}

resource function 'Microsoft.Web/sites@2024-04-01' = {
  name: 'function-${uniqueName}'
  location: resourceGroup().location
  tags: union(tags, { 'azd-service-name': 'function' })
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    
    serverFarmId: servicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: '${storageAccountName}functions'
        }
        {
          name:'AZURE_APPCONFIG_ENDPOINT'
          value: createdAppConfiguration.properties.endpoint
        }
        {
          name: 'MyQueueName'
          value: '@Microsoft.AppConfiguration(Endpoint=${createdAppConfiguration.properties.endpoint};Key=TestApp:Storage:QueueName)'
        }
      ]
    }
    clientAffinityEnabled: false
    httpsOnly: true
    reserved: false
  }
}

resource functionConfig 'Microsoft.Web/sites/config@2024-04-01' = {
  name:'web'
  parent: function
  properties:{
    netFrameworkVersion: 'v8.0'
    use32BitWorkerProcess: false
  }
}

resource roleAssignmentManagedIdentity 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: createdAppConfiguration
  name: guid(createdAppConfiguration.name, resourceGroup().id, 'App Configuration Data Owner')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b')
    principalId: function.identity.principalId
  }
}

output baseUrl string = function.properties.defaultHostName
