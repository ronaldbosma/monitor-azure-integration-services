//=============================================================================
// Failed APIM Requests Alert
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

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The name of the App Insights instance')
param appInsightsName string

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

//=============================================================================
// Resources
//=============================================================================

resource failedApimRequestsAlertBasedOnLogging 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: getResourceName('alert', environmentName, location, 'failed-apim-requests-logging')
  location: location
  tags: tags

  properties: {
    description: 'Alert that triggers when an API Management request fails (based on logging)'
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
    windowSize: 'PT5M' // Look at the failed API Management requests from the last 5 minutes

    criteria: {
      allOf: [
        {
          query: '''
            requests
            | where customDimensions["Service Type"] == "API Management"
            | where success == false
            | where resultCode !in (400, 404, 409, 412)
            | extend api = tostring(customDimensions["API Name"])
            | extend operation = tostring(customDimensions["Operation Name"])
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: 1

          // These dimensions are used to split the alerts on the name of the API Management service, API and operation.
          dimensions: [
            {
              name: 'cloud_RoleName'
              operator: 'Include'
              values: [
                '*'
              ]
            }
            {
              name: 'api'
              operator: 'Include'
              values: [
                '*'
              ]
            }
            {
              name: 'operation'
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

resource failedApimRequestsAlertBasedOnMetric 'Microsoft.Insights/metricAlerts@2026-01-01' = {
  name: getResourceName('alert', environmentName, location, 'failed-apim-requests-metric')
  location: 'global'
  tags: tags

  properties: {
    description: 'Alert that triggers when an API Management request fails (based on metric)'
    severity: 1
    enabled: true
    autoMitigate: false

    scopes: [
      appInsights.id
    ]
    targetResourceType: 'microsoft.insights/components'
    targetResourceRegion: appInsights.location

    evaluationFrequency: 'PT1M' // Execute every 1 minute
    windowSize: 'PT5M' // Look at the failed API Management requests from the last 5 minutes

    criteria: {
      allOf: [
        {

          // There's no API Management specific metric for failed requests as there is with Logic App workflows, so we're using failed requests.
          // Available metrics can be found here: https://learn.microsoft.com/en-us/azure/azure-monitor/app/metrics-overview?tabs=standard#failure-metrics
          name: 'FailedApimRequestMetric'
          metricNamespace: 'microsoft.insights/components'
          metricName: 'requests/failed'

          // Alert triggers when the number of failed API Management requests is greater than 0
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 0

          // These dimensions are used to split the alerts on the name of the API Management service. There's no dimension for e.g. the API name or operation.
          dimensions: [
            {
              name: 'cloud/roleName'
              operator: 'StartsWith' // Cloud role name of the API Management service includes the location, so we use 'StartsWith' to match the service name regardless of the location suffix.
              values: [
                apiManagementServiceName // Only trigger on failed requests for the API Management service. Ignore other failed requests from e.g. the Function App.
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
