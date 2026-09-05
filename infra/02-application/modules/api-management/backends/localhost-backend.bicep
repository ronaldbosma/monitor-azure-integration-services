//=============================================================================
// Localhost Backend
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

resource localhostApimSubscription 'Microsoft.ApiManagement/service/subscriptions@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'localhost'
  properties: {
    displayName: 'Localhost Subscription'
    scope: '/apis'
    state: 'active'
  }
}

resource localhostApimSubscriptionKeySecret 'Microsoft.KeyVault/vaults/secrets@2026-02-01' = {
  name: 'localhost-apim-subscription-key'
  parent: keyVault
  properties: {
    value: localhostApimSubscription.listSecrets(apiManagementService.apiVersion).primaryKey
  }
}

resource localhostApimSubscriptionKeyNamedValue 'Microsoft.ApiManagement/service/namedValues@2025-09-01-preview' = {
  name: 'localhost-apim-subscription-key'
  parent: apiManagementService
  properties: {
    displayName: 'localhost-apim-subscription-key'
    secret: true
    keyVault: {
      secretIdentifier: localhostApimSubscriptionKeySecret.properties.secretUri
    }
  }
}

resource localhostBaseUrlNamedValue 'Microsoft.ApiManagement/service/namedValues@2025-09-01-preview' = {
  name: 'localhost-base-url'
  parent: apiManagementService
  properties: {
    displayName: 'localhost-base-url'
    secret: false
    value: apiManagementService.properties.gatewayUrl
  }
}

resource localhostBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'localhost'
  properties: {
    description: 'The localhost backend. Can be used to call other APIs hosted in the same API Management instance.'

    // Note: This configuration uses the public gateway URL for the backend.
    // For APIM instances running inside a VNet, you would typically use https://localhost as the backend URL.
    url: apiManagementService.properties.gatewayUrl
    protocol: 'http'

    // Note: The Host header configuration is only necessary when the backend URL is set to https://localhost.
    // For public gateway URLs, this configuration can be omitted.
    credentials: {
      header: {
        Host: [
          parseUri(apiManagementService.properties.gatewayUrl).host
        ]
        'Ocp-Apim-Subscription-Key': [
          '{{localhost-apim-subscription-key}}'
        ]
      }
    }

    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }

  dependsOn: [
    localhostApimSubscriptionKeyNamedValue
  ]
}
