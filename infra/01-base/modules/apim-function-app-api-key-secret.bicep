//=============================================================================
// Function App API key secret for API Management
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('The API key for the Function App backend')
@secure()
param apiKey string = base64(newGuid())

//=============================================================================
// Existing resources
//=============================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2026-05-15' existing = {
  name: keyVaultName
}
//=============================================================================
// Resources
//=============================================================================

@onlyIfNotExists() // Only create the secret if it doesn't already exist to prevent a mismatch between the secret and function app API key
resource apimFunctionAppApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2026-05-15' = {
  name: 'apim-function-app-api-key'
  parent: keyVault
  properties: {
    value: apiKey
  }
}
