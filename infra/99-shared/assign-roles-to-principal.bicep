//=============================================================================
// Assign roles to principal on resources like App Insights and Key Vault
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The id of the principal that will be assigned the roles')
param principalId string

@description('The type of the principal that will be assigned the roles')
param principalType string?

@description('The flag to determine if the principal is an admin or not')
param isAdmin bool = false

@description('The name of the App Insights instance on which to assign roles')
param appInsightsName string

@description('The name of the Key Vault on which to assign roles')
param keyVaultName string

@description('The name of the Service Bus namespace on which to assign roles')
param serviceBusNamespaceName string

@description('The name of the Storage Account on which to assign roles')
param storageAccountName string

//=============================================================================
// Variables
//=============================================================================

var keyVaultRoleName string = isAdmin ? 'Key Vault Administrator' : 'Key Vault Secrets User'

var monitoringMetricsPublisherRoleName string = 'Monitoring Metrics Publisher'

var serviceBusRoleNames string[] = [
  'Azure Service Bus Data Receiver'
  'Azure Service Bus Data Sender'
]

var storageAccountRoleNames string[] = [
  'Storage Blob Data Contributor'
  isAdmin
    ? 'Storage File Data Privileged Contributor' // is able to browse file shares in Azure Portal
    : 'Storage File Data SMB Share Contributor'
  'Storage Queue Data Contributor'
  'Storage Table Data Contributor'
]

//=============================================================================
// Existing Resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' existing = {
  name: keyVaultName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2026-01-01' existing = {
  name: serviceBusNamespaceName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' existing = {
  name: storageAccountName
}

//=============================================================================
// Resources
//=============================================================================

// Assign role Application Insights to the principal

resource assignAppInsightRolesToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, appInsights.id, monitoringMetricsPublisherRoleName)
  scope: appInsights
  properties: {
    roleDefinitionId: roleDefinitions(monitoringMetricsPublisherRoleName).id
    principalId: principalId
    principalType: principalType
  }
}

// Assign role on Key Vault to the principal

resource assignRolesOnKeyVaultToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, keyVault.id, keyVaultRoleName)
  scope: keyVault
  properties: {
    roleDefinitionId: roleDefinitions(keyVaultRoleName).id
    principalId: principalId
    principalType: principalType
  }
}

// Assign roles on Service Bus to the principal (if Service Bus is included)

resource assignRolesOnServiceBusToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in serviceBusRoleNames: {
    name: guid(principalId, serviceBusNamespace.id, role)
    scope: serviceBusNamespace
    properties: {
      roleDefinitionId: roleDefinitions(role).id
      principalId: principalId
      principalType: principalType
    }
  }
]

// Assign roles on Storage Account to the principal

resource assignRolesOnStorageAccountToPrincipal 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for role in storageAccountRoleNames: {
    name: guid(principalId, storageAccount.id, role)
    scope: storageAccount
    properties: {
      roleDefinitionId: roleDefinitions(role).id
      principalId: principalId
      principalType: principalType
    }
  }
]
