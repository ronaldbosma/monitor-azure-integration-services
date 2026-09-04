//=============================================================================
// Movies API in API Management
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apiManagementServiceName
}

//=============================================================================
// Resources
//=============================================================================

resource moviesApi 'Microsoft.ApiManagement/service/apis@2025-09-01-preview' = {
  name: 'movies-api'
  parent: apiManagementService
  properties: {
    path: 'movies'
    format: 'openapi'
    value: loadTextContent('movies-api.openapi.yaml')
    type: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}
