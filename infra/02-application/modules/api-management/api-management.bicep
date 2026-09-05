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

// Policy Fragments

resource handleErrorResponseFragment 'Microsoft.ApiManagement/service/policyFragments@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'handle-error-response'
  properties: {
      format: 'rawxml'
      value: loadTextContent('policy-fragments/handle-error-response.xml')
  }
}

resource logErrorFragment 'Microsoft.ApiManagement/service/policyFragments@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'log-error'
  properties: {
      format: 'rawxml'
      value: loadTextContent('policy-fragments/log-error.xml')
  }
}

resource validateRequestFragment 'Microsoft.ApiManagement/service/policyFragments@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'validate-request'
  properties: {
      format: 'rawxml'
      value: loadTextContent('policy-fragments/validate-request.xml')
  }
}

// Global policies

resource globalPolicies 'Microsoft.ApiManagement/service/policies@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'policy'
  properties: {
      format: 'rawxml'
      value: loadTextContent('global.xml')
  }

  dependsOn: [
    handleErrorResponseFragment
    logErrorFragment
    validateRequestFragment
  ]
}

// APIs

module moviesApi 'apis/movies-api/movies-api.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
  }

  dependsOn: [
    globalPolicies
  ]
}

module userRatingsApi 'apis/user-ratings-api/user-ratings-api.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
  }

  dependsOn: [
    globalPolicies
  ]
}
