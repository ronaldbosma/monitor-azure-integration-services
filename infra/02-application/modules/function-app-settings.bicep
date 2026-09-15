//=============================================================================
// Function App - App Settings
// Among other things, sets up connectivity to other resources
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../99-shared/helpers.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the Function App')
param functionAppName string

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the storage account that will be used by the Function App')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var appSettings resourceInput<'Microsoft.Web/sites/config@2025-03-01'>.properties = {
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

resource functionApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: functionAppName
}

//=============================================================================
// Resources
//=============================================================================

// Set standard App Settings
//  NOTE: this is done in a separate module that merges the app settings with the existing ones
//        to prevent other (manually) created app settings from being removed.

module setFunctionAppSettings '../../99-shared/merge-app-settings.bicep' = {
  params: {
    siteName: functionAppName
    currentAppSettings: list('${functionApp.id}/config/appsettings', functionApp.apiVersion).properties
    newAppSettings: appSettings
  }
}
