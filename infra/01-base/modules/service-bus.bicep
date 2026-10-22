//=============================================================================
// Service Bus
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { serviceBusSettingsType } from '../../99-shared/settings.bicep'
import { tagsType } from '../../99-shared/types.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags tagsType

@description('The settings for the Service Bus namespace')
param serviceBusSettings serviceBusSettingsType

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

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2026-01-01' = {
  name: serviceBusSettings.namespaceName
  location: location
  tags: tags
  sku: {
    name: 'Standard' // Standard is the minimum version that supports topics
  }
  properties: {
    minimumTlsVersion: '1.2'
  }
}

#disable-next-line use-recent-api-versions // There isn't a newer version at the moment
resource serviceBusNamespaceDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${serviceBusNamespace.name}-diag'
  scope: serviceBusNamespace
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logAnalyticsDestinationType: 'Dedicated'
    logs: [
      {
        category: 'RuntimeAuditLogs'
        enabled: true
      }
      {
        category: 'DiagnosticErrorLogs'
        enabled: true
      }
      {
        category: 'ApplicationMetricsLogs'
        enabled: true
      }
    ]
  }
}

//=============================================================================
// Outputs
//=============================================================================

output serviceBusEndpoint string = serviceBusNamespace.properties.serviceBusEndpoint
