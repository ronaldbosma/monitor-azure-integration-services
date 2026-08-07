//=============================================================================
// Sets up connectivity from Logic App to other resources
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

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('The name of the Logic App')
param logicAppName string

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the storage account that will be used by the Logic App')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var appSettings resourceInput<'Microsoft.Web/sites/config@2025-03-01'>.properties = {
  // API Management App Settings
  ApiManagement_gatewayUrl: helpers.getApiManagementGatewayUrl(apiManagementServiceName)
  ApiManagement_subscriptionKey: helpers.getKeyVaultSecretReference(keyVaultName, 'logic-app-apim-subscription-key')

  // Service Bus App Settings
  ServiceBus_fullyQualifiedNamespace: helpers.getServiceBusFullyQualifiedNamespace(serviceBusNamespaceName)

  // Storage Account App Settings
  AzureBlob_blobStorageEndpoint: helpers.getBlobStorageEndpoint(storageAccountName)
  AzureFile_storageAccountUri: helpers.getFileStorageEndpoint(storageAccountName)
  AzureQueues_queueServiceUri: helpers.getQueueStorageEndpoint(storageAccountName)
  AzureTables_tableStorageEndpoint: helpers.getTableStorageEndpoint(storageAccountName)
}

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-03-01-preview' existing = {
  name: apiManagementServiceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2026-02-01' existing = {
  name: keyVaultName
}

resource logicApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: logicAppName
}

//=============================================================================
// Resources
//=============================================================================

// Logic App Subscription on all APIs in API Management Service

resource logicAppApimSubscription 'Microsoft.ApiManagement/service/subscriptions@2025-03-01-preview' = {
  parent: apiManagementService
  name: 'logic-app'
  properties: {
    displayName: 'Logic App Subscription'
    scope: '/apis'
    state: 'active'
  }
}

resource logicAppApimSubscriptionKeySecret 'Microsoft.KeyVault/vaults/secrets@2026-02-01' = {
  name: 'logic-app-apim-subscription-key'
  parent: keyVault
  properties: {
    value: logicAppApimSubscription.listSecrets(apiManagementService.apiVersion).primaryKey
  }
}

// Set standard App Settings
//  NOTE: this is done in a separate module that merges the app settings with the existing ones
//        to prevent other (manually) created app settings from being removed.

module setLogicAppSettings '../../../99-shared/merge-app-settings.bicep' = {
  params: {
    siteName: logicAppName
    currentAppSettings: list('${logicApp.id}/config/appsettings', logicApp.apiVersion).properties
    newAppSettings: appSettings
  }
  dependsOn: [
    logicAppApimSubscriptionKeySecret
  ]
}
