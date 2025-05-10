@description('The tags to associate with the resource')
param tags object

param name string

var uniqueName = uniqueString(resourceGroup().id, subscription().id)

resource appConfiguation 'Microsoft.AppConfiguration/configurationStores@2024-05-01' = {
  name: name
  location: resourceGroup().location
  tags: tags
  sku: {
    name: 'developer'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    dataPlaneProxy: {
      authenticationMode: 'Pass-through'
      privateLinkDelegation: 'Disabled'
    }
  }
}

var identityName = 'identity-${uniqueName}'

resource userId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  location: resourceGroup().location
  name: identityName
  tags: tags
}

resource roleAssignmentIdentityAppConfigurationDataOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: appConfiguation
  name: guid(appConfiguation.name, resourceGroup().id, identityName, 'App Configuration Data Owner')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b')
    principalId: userId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentIdentityAppConfigurationContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: appConfiguation
  name: guid(appConfiguation.name, resourceGroup().id, identityName, 'App Configuration Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fe86443c-f201-4fc4-9d2a-ac61149fbda0')
    principalId: userId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource roleAssignmentDeployerAppConfigurationDataOwner 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: appConfiguation
  name: guid(appConfiguation.name, resourceGroup().id, deployer().objectId, 'App Configuration Data Owner')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5ae67dd6-50cb-40e7-96ff-dc2bfa4b606b')
    principalId: deployer().objectId
    principalType: 'User'
  }
}

resource roleAssignmentDeployerAppConfigurationContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: appConfiguation
  name: guid(appConfiguation.name, resourceGroup().id, deployer().objectId, 'App Configuration Contributor')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fe86443c-f201-4fc4-9d2a-ac61149fbda0')
    principalId: deployer().objectId
    principalType: 'User'
  }
}

//It takes a while for the role assignment to be applied, so we need to wait for a while before we can use the app configuration.
resource deploymentWaitScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'Wait'
  location: resourceGroup().location
  dependsOn: [
    roleAssignmentIdentityAppConfigurationDataOwner
    roleAssignmentIdentityAppConfigurationContributor
    roleAssignmentDeployerAppConfigurationDataOwner
    roleAssignmentDeployerAppConfigurationContributor
  ]
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.70.0' //There must a better way to automatically use latest instead of keep on updating the version.
    scriptContent: 'echo "Waiting for 2 minutes..." && sleep 120'
    retentionInterval: 'PT1H'
  }
}

resource TestAppSettingsMessage 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = {
  parent: appConfiguation
  dependsOn: [deploymentWaitScript]
  name: 'TestApp:Settings:Message'
  properties: {
    value: 'Data from Azure App Configuration'
  }
}

resource TestAppSettingsQueueName 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = {
  parent: appConfiguation
  dependsOn: [deploymentWaitScript]
  name: 'TestApp:Storage:QueueName'
  properties: {
    value: 'demo'
  }
}

resource deploymentAddFeatureScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'AddFeature'
  location: resourceGroup().location
  dependsOn: [deploymentWaitScript]
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userId.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.69.0' //There must a better way to automatically use latest instead of keep on updating the version.
    scriptContent: 'az appconfig feature set -n ${appConfiguation.name} --feature Beta -y --auth-mode login '
    retentionInterval: 'PT1H'
  }
}

output name string = appConfiguation.name
