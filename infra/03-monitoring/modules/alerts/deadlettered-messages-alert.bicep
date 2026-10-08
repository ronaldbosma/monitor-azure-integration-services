//=============================================================================
// Deadlettered Messages Alert for Service Bus Namespace
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { getResourceName } from '../../../99-shared/naming-conventions.bicep'
import { tagsType } from '../../../99-shared/types.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the environment to deploy to')
param environmentName string

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags tagsType

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

//=============================================================================
// Existing resources
//=============================================================================

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2026-01-01' existing = {
  name: serviceBusNamespaceName
}

//=============================================================================
// Resources
//=============================================================================

resource deadLetteredMessagesAlert 'microsoft.insights/metricAlerts@2026-01-01' = {
  name: getResourceName('alert', environmentName, location, 'deadlettered-messages')
  location: 'global'
  tags: tags

  properties: {
    description: 'Alert that triggers when there are deadlettered messages in the Service Bus namespace'
    severity: 1
    enabled: true
    autoMitigate: true

    scopes: [
      serviceBusNamespace.id
    ]
    targetResourceType: 'Microsoft.ServiceBus/namespaces'
    targetResourceRegion: serviceBusNamespace.location

    evaluationFrequency: 'PT1M' // Execute every 1 minute
    windowSize: 'PT5M' // Look at the results from the last 5 minutes

    criteria: {
      allOf: [
        {
          // See https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-servicebus-namespaces-metrics for supported Service Bus metrics
          name: 'DeadLetteredMessagesMetric'
          metricNamespace: 'Microsoft.ServiceBus/namespaces'
          metricName: 'DeadLetteredMessages'

          // Alert triggers when there are deadlettered messages
          timeAggregation: 'Maximum'
          operator: 'GreaterThan'
          threshold: 0

          // This dimension is used to split the alerts on the name of the topic/queue.
          dimensions: [
            {
              name: 'EntityName'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]

          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
  }
}
