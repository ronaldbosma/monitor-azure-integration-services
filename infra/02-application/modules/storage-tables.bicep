//=============================================================================
// Storage Account Tables
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('Name of the storage account')
param storageAccountName string

//=============================================================================
// Existing resources
//=============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2026-04-01' existing = {
  name: storageAccountName
}

resource storageAccountTableServices 'Microsoft.Storage/storageAccounts/tableServices@2026-04-01' existing = {
  parent: storageAccount
  name: 'default'
}

//=============================================================================
// Resources
//=============================================================================

resource userRatingsTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2026-04-01' = {
  parent: storageAccountTableServices
  name: 'userratings'
}

resource moviesTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2026-04-01' = {
  parent: storageAccountTableServices
  name: 'movies'
}
