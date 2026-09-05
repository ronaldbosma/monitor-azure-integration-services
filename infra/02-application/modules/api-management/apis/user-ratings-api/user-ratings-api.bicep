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
    path: 'user-ratings'
    format: 'openapi'
    value: loadTextContent('user-ratings-api.openapi.yaml')
    type: 'http'
    protocols: [
      'https'
    ]
    subscriptionRequired: true
  }
}

resource getUserRatingsOperation 'Microsoft.ApiManagement/service/apis/operations@2025-09-01-preview' existing = {
  name: 'get-user-ratings'
  parent: userRatingsApi

  resource policies 'policies' = {
    name: 'policy'
    properties: {
      format: 'rawxml'
      value: loadTextContent('operations/get-user-ratings.xml')
    }
  }
}

resource insertOrUpdateUserRatingOperation 'Microsoft.ApiManagement/service/apis/operations@2025-09-01-preview' existing = {
  name: 'insert-or-update-user-rating'
  parent: userRatingsApi

  resource policies 'policies' = {
    name: 'policy'
    properties: {
      format: 'rawxml'
      value: loadTextContent('operations/insert-or-update-user-rating.xml')
    }
  }
}
