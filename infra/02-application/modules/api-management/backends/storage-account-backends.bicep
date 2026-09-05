//=============================================================================
// Storage Account Backends
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import * as helpers from '../../../../99-shared/helpers.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management Service')
param apiManagementServiceName string

@description('Name of the storage account')
param storageAccountName string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

resource blobStorageBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
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

resource queueStorageBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
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

resource tableStorageBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
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
