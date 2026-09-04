//=============================================================================
// User Ratings API in API Management
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

resource userRatingsApi 'Microsoft.ApiManagement/service/apis@2025-09-01-preview' = {
  name: 'user-ratings-api'
  parent: apiManagementService
  properties: {
    displayName: 'User Ratings API'
    path: 'user-ratings'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}
