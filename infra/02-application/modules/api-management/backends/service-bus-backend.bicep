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

resource apiManagementService 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

resource serviceBusFqdnNamedValue 'Microsoft.ApiManagement/service/namedValues@2025-09-01-preview' = {
  name: 'service-bus-fqdn'
  parent: apiManagementService
  properties: {
    displayName: 'service-bus-fqdn'
    secret: false
    value: helpers.getServiceBusFullyQualifiedNamespace(serviceBusNamespaceName)
  }
}

resource serviceBusBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
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
