//=============================================================================
// Monitor Azure Integration Services - Base layer
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getResourceName, generateInstanceId } from '../99-shared/naming-conventions.bicep'
import { getTemplateTags } from '../99-shared/helpers.bicep'
import { apiManagementSettingsType, appInsightsSettingsType, functionAppSettingsType, logicAppSettingsType, serviceBusSettingsType } from '../99-shared/settings.bicep'
import { tagsType } from '../99-shared/types.bicep'

//=============================================================================
// Parameters
//=============================================================================

@minLength(1)
@description('Location to use for all resources')
param location string

@minLength(1)
@maxLength(32)
@description('The name of the environment to deploy to')
param environmentName string

//=============================================================================
// Variables
//=============================================================================

// Generate an instance ID to ensure unique resource names
var instanceId string = generateInstanceId(environmentName, location)

var resourceGroupName string = getResourceName('resourceGroup', environmentName, location, instanceId)

var apiManagementSettings apiManagementSettingsType = {
  serviceName: getResourceName('apiManagement', environmentName, location, instanceId)
  sku: 'Consumption'
}

var appInsightsSettings appInsightsSettingsType = {
  appInsightsName: getResourceName('applicationInsights', environmentName, location, instanceId)
  logAnalyticsWorkspaceName: getResourceName('logAnalyticsWorkspace', environmentName, location, instanceId)
  retentionInDays: 30
}

var functionAppSettings functionAppSettingsType = {
  functionAppName: getResourceName('functionApp', environmentName, location, instanceId)
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'functionapp-${instanceId}')
  netFrameworkVersion: 'v10.0'
}

var logicAppSettings logicAppSettingsType = {
  logicAppName: getResourceName('logicApp', environmentName, location, instanceId)
  appServicePlanName: getResourceName('appServicePlan', environmentName, location, 'logicapp-${instanceId}')
  netFrameworkVersion: 'v8.0'
}

var keyVaultName string = getResourceName('keyVault', environmentName, location, instanceId)

var serviceBusSettings serviceBusSettingsType = {
  namespaceName: getResourceName('serviceBusNamespace', environmentName, location, instanceId)
}

var storageAccountName string = getResourceName('storageAccount', environmentName, location, instanceId)

var tags tagsType = getTemplateTags(environmentName)

//=============================================================================
// Resources
//=============================================================================

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module keyVault 'modules/key-vault.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    keyVaultName: keyVaultName
  }
}
module serviceBus 'modules/service-bus.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    serviceBusSettings: serviceBusSettings
  }
}

module storageAccount 'modules/storage-account.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    storageAccountName: storageAccountName
  }
}

module appInsights 'modules/app-insights.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    appInsightsSettings: appInsightsSettings
  }
}

module apiManagement 'modules/api-management.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    apiManagementSettings: apiManagementSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    serviceBusNamespaceName: serviceBusSettings.namespaceName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    keyVault
  ]
}

module functionApp 'modules/function-app.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    functionAppSettings: functionAppSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    serviceBusNamespaceName: serviceBusSettings.namespaceName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    keyVault
    storageAccount
  ]
}

module logicApp 'modules/logic-app.bicep' = {
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logicAppSettings: logicAppSettings
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    serviceBusNamespaceName: serviceBusSettings.namespaceName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
    keyVault
    storageAccount
  ]
}

module connectivity 'modules/connectivity/connectivity.bicep' = {
  scope: resourceGroup
  params: {
    apiManagementServiceName: apiManagementSettings.serviceName
    functionAppName: functionAppSettings.functionAppName
    keyVaultName: keyVaultName
    logicAppName: logicAppSettings.logicAppName
    serviceBusNamespaceName: serviceBusSettings.namespaceName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    apiManagement
    functionApp
    keyVault
    logicApp
    serviceBus
    storageAccount
  ]
}

module assignRolesToDeployer '../99-shared/assign-roles-to-principal.bicep' = {
  scope: resourceGroup
  params: {
    principalId: deployer().objectId
    appInsightsName: appInsightsSettings.appInsightsName
    keyVaultName: keyVaultName
    serviceBusNamespaceName: serviceBusSettings.namespaceName
    storageAccountName: storageAccountName
  }
  dependsOn: [
    appInsights
  ]
}

//=============================================================================
// Outputs
//=============================================================================

// Return the Azure tenant id so it is available in the .env file and can be used in e.g. the integration tests
output AZURE_TENANT_ID string = subscription().tenantId

// Return the names of the resources
output AZURE_API_MANAGEMENT_NAME string = apiManagementSettings.serviceName
output AZURE_APPLICATION_INSIGHTS_NAME string = appInsightsSettings.appInsightsName
output AZURE_FUNCTION_APP_NAME string = functionAppSettings.functionAppName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = appInsightsSettings.logAnalyticsWorkspaceName
output AZURE_LOGIC_APP_NAME string = logicAppSettings.logicAppName
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_SERVICE_BUS_NAMESPACE_NAME string = serviceBusSettings.namespaceName
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccountName

// Return resource endpoints
output AZURE_API_MANAGEMENT_GATEWAY_URL string = apiManagement.outputs.gatewayUrl
output AZURE_FUNCTION_APP_ENDPOINT string = functionApp.outputs.endpoint
output AZURE_KEY_VAULT_URI string = keyVault.outputs.vaultUri
output AZURE_LOGIC_APP_ENDPOINT string = logicApp.outputs.endpoint
output AZURE_SERVICE_BUS_NAMESPACE_ENDPOINT string = serviceBus.outputs.serviceBusEndpoint
