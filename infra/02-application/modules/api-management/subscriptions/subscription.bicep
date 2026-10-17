//=============================================================================
// API Management Subscription on all APIs, key is stored in Key Vault
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management Service')
param apiManagementServiceName string

@description('The name of the subscription')
param name string

@description('The display name of the subscription')
param displayName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apiManagementServiceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2026-05-15' existing = {
  name: keyVaultName
}

//=============================================================================
// Resources
//=============================================================================

resource apimSubscription 'Microsoft.ApiManagement/service/subscriptions@2025-09-01-preview' = {
  parent: apiManagementService
  name: name
  properties: {
    displayName: displayName
    scope: '/apis'
    state: 'active'
  }
}

resource apimSubscriptionKeySecret 'Microsoft.KeyVault/vaults/secrets@2026-05-15' = {
  name: '${name}-apim-subscription-key'
  parent: keyVault
  properties: {
    value: apimSubscription.listSecrets(apiManagementService.apiVersion).primaryKey
  }
}
