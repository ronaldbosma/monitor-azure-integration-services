//=============================================================================
// Recalculate Rating For All Movies Workflow Not Started Alert
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

resource failedWorkflowAlertBasedOnMetric 'Microsoft.Insights/metricAlerts@2026-01-01' = {
  name: getResourceName('alert', environmentName, location, 'recalculate-ratings-workflow-not-started')
  location: 'global'
  tags: tags

  properties: {
    description: 'Alert that triggers when the workflow "recalculate-rating-for-all-movies" did not start'
    severity: 2
    enabled: true
    autoMitigate: true

    scopes: [
      logicApp.id
    ]
    targetResourceType: 'Microsoft.Web/sites'
    targetResourceRegion: logicApp.location

    evaluationFrequency: 'PT5M' // Execute every 5 minutes
    windowSize: 'PT15M' // Look at the workflow failures from the last 15 minutes

    criteria: {
      allOf: [
        {
          // See https://learn.microsoft.com/en-us/azure/azure-monitor/reference/supported-metrics/microsoft-web-sites-metrics for supported site metrics
          name: 'RecalculateRatingForAllMoviesWorkflowNotStartedMetric'
          metricNamespace: 'Microsoft.Web/sites'
          metricName: 'WorkflowRunsStarted'

          // Alert triggers when the total number of workflow runs started is 0
          timeAggregation: 'Total'
          operator: 'Equals'
          threshold: 0

          dimensions: [
            {
              name: 'workflowName'
              operator: 'Include'
              values: [
                'recalculate-rating-for-all-movies'
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
