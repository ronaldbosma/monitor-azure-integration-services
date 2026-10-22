//=============================================================================
// Storage Account
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { tagsType } from '../../99-shared/types.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags tagsType

@description('Name of the storage account that will be created')
@maxLength(24)
param storageAccountName string

@description('The name of the Log Analytics workspace that the diagnostic settings will send logs and metrics to')
param logAnalyticsWorkspaceName string

//=============================================================================
// Existing resources
//=============================================================================

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2026-03-01' existing = {
  name: logAnalyticsWorkspaceName
}

//=============================================================================
// Resources
//=============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2026-04-01'  = {
  name: 'default'
  parent: storageAccount
}

#disable-next-line use-recent-api-versions // There isn't a newer version at the moment
resource storageTableDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${storageAccountName}-table-diag'
  scope: tableService
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        categoryGroup: 'AllLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

//=============================================================================
// Outputs
//=============================================================================

output tableEndpoint string = storageAccount.properties.primaryEndpoints.table

