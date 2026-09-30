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

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

//=============================================================================
// Resources
//=============================================================================

resource failedWorkflowAlert 'Microsoft.Insights/scheduledQueryRules@2026-03-01' = {
  name: getResourceName('alert', environmentName, location, 'failed-workflow')
  location: location
  tags: tags

  properties: {
    displayName: 'Failed Workflow Alert'
    description: 'Alert that triggers when a workflow fails'
    severity: 1
    enabled: true
    autoMitigate: false

    windowSize: 'PT5M' // Look at the workflow failures from the last 5 minutes
    evaluationFrequency: 'PT5M' // Execute every 5 minutes

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

    scopes: [
      appInsights.id
    ]

    targetResourceTypes: [
      'Microsoft.Insights/components'
    ]
  }
}
