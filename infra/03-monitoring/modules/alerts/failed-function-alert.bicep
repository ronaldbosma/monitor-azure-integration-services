//=============================================================================
// Failed Function Alert
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

@description('The name of the App Insights instance')
param appInsightsName string

@description('The name of the Function App')
param functionAppName string

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

//=============================================================================
// Resources
//=============================================================================

resource failedFunctionAlertBasedOnLogging 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: getResourceName('alert', environmentName, location, 'failed-function-logging')
  location: location
  tags: tags

  properties: {
    description: 'Alert that triggers when a function fails (based on logging)'
    severity: 1
    enabled: true
    autoMitigate: false

    scopes: [
      appInsights.id
    ]
    targetResourceTypes: [
      'Microsoft.Insights/components'
    ]

    evaluationFrequency: 'PT5M' // Execute every 5 minutes
    windowSize: 'PT5M' // Look at the function failures from the last 5 minutes

    criteria: {
      allOf: [
        {
          query: '''
            requests
            | extend functionName = tostring(customDimensions['faas.name'])
            | where functionName != '' // Only include Azure Function related requests
            | where success == false
            | where resultCode !in (400, 404, 409, 412)
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: 1

          // These dimensions are used to split the alerts on the name of the Function App and function.
          dimensions: [
            {
              name: 'cloud_RoleName'
              operator: 'Include'
              values: [
                '*'
              ]
            }
            {
              name: 'functionName'
              operator: 'Include'
              values: [
                '*'
              ]
            }
          ]
        }
      ]
    }
  }
}

resource failedFunctionAlertBasedOnMetric 'Microsoft.Insights/metricAlerts@2026-01-01' = {
  name: getResourceName('alert', environmentName, location, 'failed-function-metric')
  location: 'global'
  tags: tags

  properties: {
    description: 'Alert that triggers when a function fails (based on metric)'
    severity: 1
    enabled: true
    autoMitigate: false

    scopes: [
      appInsights.id
    ]
    targetResourceType: 'microsoft.insights/components'
    targetResourceRegion: appInsights.location

    evaluationFrequency: 'PT1M' // Execute every 1 minute
    windowSize: 'PT5M' // Look at the function failures from the last 5 minutes

    criteria: {
      allOf: [
        {

          // There's no Azure Functions specific metric for failed functions as there is with Logic App workflows, so we're using failed requests.
          // Available metrics can be found here: https://learn.microsoft.com/en-us/azure/azure-monitor/app/metrics-overview?tabs=standard#failure-metrics
          name: 'FailedFunctionMetric'
          metricNamespace: 'microsoft.insights/components'
          metricName: 'requests/failed'

          // Alert triggers when the number of failed functions is greater than 0
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          // These dimensions are used to split the alerts on the name of the Function App. There's no dimension for function names.
          dimensions: [
            {
              name: 'cloud/roleName'
              operator: 'Include'
              values: [
                functionAppName // Only trigger on failed requests for the Function App. Ignore other failed requests from e.g. API Management.
              ]
            }
            {
              name: 'request/resultCode'
              operator: 'Exclude'
              // Ignore client errors we're not interested in
              values: [
                '400'
                '404'
                '409'
                '412'
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
