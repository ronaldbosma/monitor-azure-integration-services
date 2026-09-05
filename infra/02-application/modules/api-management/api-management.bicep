//=============================================================================
// API Management Application Resources, like APIs and global policies
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

resource globalPolicies 'Microsoft.ApiManagement/service/policies@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'policy'
  properties: {
      format: 'rawxml'
      value: loadTextContent('global.xml')
  }
}

module moviesApi 'apis/movies-api/movies-api.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
  }
}

module userRatingsApi 'apis/user-ratings-api/user-ratings-api.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
  }
}
