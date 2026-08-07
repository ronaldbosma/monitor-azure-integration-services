//=============================================================================
// Sets up connectivity from Function App to other resources
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../../99-shared/helpers.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management Service')
param apiManagementServiceName string

@description('The name of the Function App')
param functionAppName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the storage account that will be used by the Function App')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var appSettings resourceInput<'Microsoft.Web/sites/config@2025-03-01'>.properties = {
  // API Management App Settings
  ApiManagement__GatewayUrl: helpers.getApiManagementGatewayUrl(apiManagementServiceName)
  ApiManagement__SubscriptionKey: helpers.getKeyVaultSecretReference(keyVaultName, 'function-app-subscription-key')

  // Service Bus App Settings
  ServiceBusConnection__fullyQualifiedNamespace: helpers.getServiceBusFullyQualifiedNamespace(serviceBusNamespaceName)

  // Storage Account App Settings
  StorageAccountConnection__blobServiceUri: helpers.getBlobStorageEndpoint(storageAccountName)
  StorageAccountConnection__fileServiceUri: helpers.getFileStorageEndpoint(storageAccountName)
  StorageAccountConnection__queueServiceUri: helpers.getQueueStorageEndpoint(storageAccountName)
  StorageAccountConnection__tableServiceUri: helpers.getTableStorageEndpoint(storageAccountName)
}

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-03-01-preview' existing = {
  name: apiManagementServiceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource functionApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: functionAppName
}

//=============================================================================
// Resources
//=============================================================================

// Function App Subscription on all APIs in API Management Service

resource functionAppSubscription 'Microsoft.ApiManagement/service/subscriptions@2025-03-01-preview' = {
  parent: apiManagementService
  name: 'function-app'
  properties: {
    displayName: 'Function App Subscription'
    scope: '/apis'
    state: 'active'
  }
}

resource functionAppSubscriptionKeySecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: 'function-app-subscription-key'
  parent: keyVault
  properties: {
    value: functionAppSubscription.listSecrets(apiManagementService.apiVersion).primaryKey
  }
}

// Set standard App Settings
//  NOTE: this is done in a separate module that merges the app settings with the existing ones
//        to prevent other (manually) created app settings from being removed.

module setFunctionAppSettings '../../../99-shared/merge-app-settings.bicep' = {
  params: {
    siteName: functionAppName
    currentAppSettings: list('${functionApp.id}/config/appsettings', functionApp.apiVersion).properties
    newAppSettings: appSettings
  }
  dependsOn: [
    functionAppSubscriptionKeySecret
  ]
}
