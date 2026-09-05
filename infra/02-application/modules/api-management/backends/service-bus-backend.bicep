//=============================================================================
// Service Bus Backend
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

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-03-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

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
