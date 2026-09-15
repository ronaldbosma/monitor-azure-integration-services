//=============================================================================
// Function App Backend
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management Service')
param apiManagementServiceName string

@description('The name of the Function App')
param functionAppName string

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

resource functionApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: functionAppName
}

//=============================================================================
// Resources
//=============================================================================

resource functionAppApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2026-02-01' = {
  name: 'function-app-api-key'
  parent: keyVault
  properties: {
    value: listKeys('${functionApp.id}/host/default', functionApp.apiVersion).functionKeys.default
  }
}

resource functionAppApiKeyNamedValue 'Microsoft.ApiManagement/service/namedValues@2025-09-01-preview' = {
  name: 'function-app-api-key'
  parent: apiManagementService
  properties: {
    displayName: 'function-app-api-key'
    secret: true
    keyVault: {
      secretIdentifier: functionAppApiKeySecret.properties.secretUri
    }
  }
}

resource functionAppBackend 'Microsoft.ApiManagement/service/backends@2025-09-01-preview' = {
  parent: apiManagementService
  name: 'function-app'
  properties: {
    description: 'The backend for the Function App'
    url: 'https://${functionApp.properties.defaultHostName}'
    protocol: 'http'
    credentials: {
      header: {
        'x-functions-key': [
          '{{function-app-api-key}}'
        ]
      }
    }
    tls: {
      validateCertificateChain: true
      validateCertificateName: true
    }
  }
  dependsOn: [
    functionAppApiKeyNamedValue
  ]
}
