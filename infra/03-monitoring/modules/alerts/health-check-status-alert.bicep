//=============================================================================
// Health Check Status Alert
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

@description('The name of the Logic App')
param logicAppName string

//=============================================================================
// Existing resources
//=============================================================================

resource logicApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: logicAppName
}

//=============================================================================
// Resources
//=============================================================================

resource healthCheckAlert 'microsoft.insights/metricAlerts@2026-01-01' = {
  name: getResourceName('alert', environmentName, location, 'logicapp-healthcheck')
  location: 'global'
  tags: tags

  properties: {
    description: 'Alert that triggers when health check on Logic App fails'
    severity: 1
    enabled: true
    autoMitigate: true

    scopes: [
      logicApp.id
    ]
    targetResourceType: 'Microsoft.Web/sites'
    targetResourceRegion: logicApp.location

    evaluationFrequency: 'PT1M' // Execute every 1 minute
    windowSize: 'PT5M' // Look at the results from the last 5 minutes

    criteria: {
      allOf: [
        {
          // See https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-web-sites-metrics for supported site metrics
          name: 'HealthCheckStatusMetric'
          metricNamespace: 'Microsoft.Web/sites'
          metricName: 'HealthCheckStatus'

          // Alert triggers when the average health check status is less than 100
          timeAggregation: 'Average'
          operator: 'LessThan'
          threshold: 100

          skipMetricValidation: false
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
  }
}
