//=============================================================================
// Failed Workflow Alert
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

@description('The name of the Logic App')
param logicAppName string

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource logicApp 'Microsoft.Web/sites@2025-03-01' existing = {
  name: logicAppName
}

//=============================================================================
// Resources
//=============================================================================

resource failedWorkflowAlertBasedOnLogging 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: getResourceName('alert', environmentName, location, 'failed-workflow-logging')
  location: location
  tags: tags

  properties: {
    description: 'Alert that triggers when a workflow fails (based on logging)'
    severity: 1
    enabled: true
    autoMitigate: true

    scopes: [
      appInsights.id
    ]
    targetResourceTypes: [
      'Microsoft.Insights/components'
    ]

    evaluationFrequency: 'PT1M' // Execute every 1 minute
    windowSize: 'PT5M' // Look at the workflow failures from the last 5 minutes

    criteria: {
      allOf: [
        {
          query: '''
            traces
            | where customDimensions["Category"] == "Workflow.Operations.Runs"
            | where customDimensions["EventName"] == "WorkflowRunEnd"
            | where customDimensions["status"] == '"Failed"'
          '''

          timeAggregation: 'Count'
          operator: 'GreaterThanOrEqual'
          threshold: 1

          // These dimensions are used to split the alerts on the name of the Logic App and workflow.
          dimensions: [
            {
              name: 'cloud_RoleName'
              operator: 'Include'
              values: [
                '*'
              ]
            }
            {
              name: 'operation_Name'
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

resource failedWorkflowAlertBasedOnMetric 'Microsoft.Insights/metricAlerts@2026-01-01' = {
  name: getResourceName('alert', environmentName, location, 'failed-workflow-metric')
  location: 'global'
  tags: tags

  properties: {
    description: 'Alert that triggers when a workflow fails (based on metric)'
    severity: 1
    enabled: true
    autoMitigate: true

    scopes: [
      logicApp.id
    ]
    targetResourceType: 'Microsoft.Web/sites'
    targetResourceRegion: logicApp.location

    evaluationFrequency: 'PT1M' // Execute every 1 minute
    windowSize: 'PT5M' // Look at the workflow failures from the last 5 minutes

    criteria: {
      allOf: [
        {
          // See https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-web-sites-metrics for supported site metrics
          name: 'FailedWorkflowMetric'
          metricNamespace: 'Microsoft.Web/sites'
          metricName: 'WorkflowRunsFailureRate'

          // Alert triggers when the total number of failed workflow runs is greater than 0
          timeAggregation: 'Total'
          operator: 'GreaterThan'
          threshold: 0

          // These dimensions are used to split the alerts on the name of the workflow.
          dimensions: [
            {
              name: 'workflowName'
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
