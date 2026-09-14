//=============================================================================
// Subscription for integration tests
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management Service')
param apiManagementServiceName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apiManagementServiceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2026-02-01' existing = {
  name: keyVaultName
}

//=============================================================================
// Resources
//=============================================================================

resource integrationTestsApimSubscription 'Microsoft.ApiManagement/service/subscriptions@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'integration-tests'
  properties: {
    displayName: 'Integration Tests Subscription'
    scope: '/apis'
    state: 'active'
  }
}

resource integrationTestsApimSubscriptionKeySecret 'Microsoft.KeyVault/vaults/secrets@2026-02-01' = {
  name: 'integration-tests-apim-subscription-key'
  parent: keyVault
  properties: {
    value: integrationTestsApimSubscription.listSecrets(apiManagementService.apiVersion).primaryKey
  }
}
