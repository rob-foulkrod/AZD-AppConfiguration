targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('The Azure App Configuration name to be created')
param appConfigurationName string

// Tags that should be applied to all resources.
// 
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
  SecurityControl: 'Ignore'
}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

module storageAccount './modules/storageAccount.bicep' = {
  name: 'storageAccount'
  scope: rg
  params: {
    tags: tags
  }
}

module azureAppConfiguration './modules/azureAppConfiguration.bicep' = {
  name: 'azureAppConfiguration'
  scope: rg
  params: {
    tags: tags
    name: appConfigurationName
    }
}

module azureFunction './modules/azureFunction.bicep' = {
  name: 'azureFunction'
  scope: rg
  params: {
    tags: tags
    storageAccountName: storageAccount.outputs.storageAccountName
    appConfigName: azureAppConfiguration.outputs.name
  }
}

output AZURE_FUNCTION_BASE_URL string = azureFunction.outputs.baseUrl
