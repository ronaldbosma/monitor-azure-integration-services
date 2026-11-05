//=============================================================================
// Function App API Key
// We're using a module so the value can come from a Key Vault secret.
// E.g. `value: keyVault.getSecret('function-app-api-key')`
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the Function App')
param functionAppName string

@description('The name of the API key')
param name string

@description('The API key for the Function App')
@secure()
param value string

//=============================================================================
// Existing resources
//=============================================================================

resource functionApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: functionAppName
}

resource functionAppHost 'Microsoft.Web/sites/host@2025-03-01' existing = {
  name: 'default'
  parent: functionApp
}

//=============================================================================
// Resources
//=============================================================================

resource functionAppKey 'Microsoft.Web/sites/host/functionKeys@2025-03-01' = {
  name: name
  parent: functionAppHost
  properties: {
    name: name
    value: value
  }
}
