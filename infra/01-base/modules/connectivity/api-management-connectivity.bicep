//=============================================================================
// Sets up connectivity from API Management to other resources
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

// Function App Backend

resource functionAppApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2025-05-01' = {
  name: 'function-app-api-key'
  parent: keyVault
  properties: {
    value: listKeys('${functionApp.id}/host/default', functionApp.apiVersion).functionKeys.default
  }
}

resource functionAppApiKeyNamedValue 'Microsoft.ApiManagement/service/namedValues@2025-03-01-preview' = {
  name: 'function-app-api-key'
  parent: apiManagementService
  properties: {
    displayName: 'function-app-api-key'
    secret: true
    keyVault: {
      secretIdentifier: functionAppApiKeySecret.properties.secretUri
    }
  }
}

resource functionAppBackend 'Microsoft.ApiManagement/service/backends@2025-03-01-preview' = {
  parent: apiManagementService
  name: 'function-app'
  properties: {
    description: 'The backend for the Function App'
    url: 'https://${functionApp.properties.defaultHostName}'
    protocol: 'http'
    credentials: {
      header: {
        'x-functions-key': [
          '{{function-app-api-key}}'
        ]
      }
    }
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
  dependsOn: [
    functionAppApiKeyNamedValue
  ]
}

// Service Bus Backend

resource serviceBusBackend 'Microsoft.ApiManagement/service/backends@2025-03-01-preview' = {
  parent: apiManagementService
  name: 'service-bus'
  properties: {
    description: 'The backend for the Service Bus'
    url: helpers.getServiceBusEndpoint(serviceBusNamespaceName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

// Storage Account Backends

resource blobStorageBackend 'Microsoft.ApiManagement/service/backends@2025-03-01-preview' = {
  parent: apiManagementService
  name: 'blob-storage'
  properties: {
    description: 'The backend for Blob Storage'
    url: helpers.getBlobStorageEndpoint(storageAccountName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

resource queueStorageBackend 'Microsoft.ApiManagement/service/backends@2025-03-01-preview' = {
  parent: apiManagementService
  name: 'queue-storage'
  properties: {
    description: 'The backend for Queue Storage'
    url: helpers.getQueueStorageEndpoint(storageAccountName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}

resource tableStorageBackend 'Microsoft.ApiManagement/service/backends@2025-03-01-preview' = {
  parent: apiManagementService
  name: 'table-storage'
  properties: {
    description: 'The backend for Table Storage'
    url: helpers.getTableStorageEndpoint(storageAccountName)
    protocol: 'http'
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
}
