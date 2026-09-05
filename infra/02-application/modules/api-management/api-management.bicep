//=============================================================================
// API Management Application Resources, like APIs and global policies
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The name of the Function App')
param functionAppName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

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

// Backends

module functionAppBackend 'backends/function-app-backend.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    functionAppName: functionAppName
    keyVaultName: keyVaultName
  }
}

module localhostBackend 'backends/localhost-backend.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    keyVaultName: keyVaultName
  }
}

module serviceBusBackend 'backends/service-bus-backend.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module storageAccountBackends 'backends/storage-account-backends.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    storageAccountName: storageAccountName
  }
}

// Policy Fragments

resource getMovieIdByTitleFragment 'Microsoft.ApiManagement/service/policyFragments@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'get-movie-id-by-title'
  properties: {
      format: 'rawxml'
      value: loadTextContent('policy-fragments/get-movie-id-by-title.xml')
  }

  dependsOn: [
    localhostBackend
  ]
}

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
    getMovieIdByTitleFragment
    serviceBusBackend
    storageAccountBackends
  ]
}

module userRatingsApi 'apis/user-ratings-api/user-ratings-api.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
  }

  dependsOn: [
    globalPolicies
    functionAppBackend
  ]
}
