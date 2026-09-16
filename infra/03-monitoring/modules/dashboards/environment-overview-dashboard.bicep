//=============================================================================
// Environment Overview Dashboard
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { tagsType } from '../../../99-shared/types.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the environment overview dashboard')
param name string

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags tagsType

@description('The name of the App Insights instance')
param appInsightsName string

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

//=============================================================================
// Variables
//=============================================================================

var dashboardTags { *: string } = union(tags, {
  'hidden-title': 'Environment Overview'
})

//=============================================================================
// Existing resources
//=============================================================================

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource serviceBusNamespace 'Microsoft.ServiceBus/namespaces@2026-01-01' existing = {
  name: serviceBusNamespaceName
}

//=============================================================================
// Resources
//=============================================================================

#disable-next-line use-recent-api-versions // The newer version 2026-04-01 is not available in every region
resource Environment_Overview 'Microsoft.Portal/dashboards@2025-04-01-preview' = {
  name: name
  location: location
  tags: dashboardTags
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 10
              y: 0
              colSpan: 8
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: appInsights.id
                          }
                          name: 'requests/count'
                          aggregationType: 7
                          namespace: 'microsoft.insights/components'
                          metricVisualization: {
                            displayName: 'Server requests'
                            resourceDisplayName: appInsights.name
                            color: '#0078D4'
                          }
                        }
                      ]
                      title: 'Server requests'
                      titleKind: 2
                      visualization: {
                        chartType: 3
                      }
                      openBladeOnClick: {
                        openBlade: true
                        destinationBlade: {
                          bladeName: 'ResourceMenuBlade'
                          parameters: {
                            id: appInsights.id
                            menuid: 'performance'
                          }
                          extensionName: 'HubsExtension'
                          options: {
                            parameters: {
                              id: appInsights.id
                              menuid: 'performance'
                            }
                          }
                        }
                      }
                    }
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: appInsights.id
                          }
                          name: 'requests/count'
                          aggregationType: 7
                          namespace: 'microsoft.insights/components'
                          metricVisualization: {
                            displayName: 'Server requests'
                            resourceDisplayName: appInsights.name
                            color: '#0078D4'
                          }
                        }
                      ]
                      title: 'Server requests'
                      titleKind: 2
                      visualization: {
                        chartType: 3
                        disablePinning: true
                      }
                      openBladeOnClick: {
                        openBlade: true
                        destinationBlade: {
                          bladeName: 'ResourceMenuBlade'
                          parameters: {
                            id: appInsights.id
                            menuid: 'performance'
                          }
                          extensionName: 'HubsExtension'
                          options: {
                            parameters: {
                              id: appInsights.id
                              menuid: 'performance'
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 18
              y: 0
              colSpan: 9
              rowSpan: 3
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                }
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      appInsights.id
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: 'f598a581-cd60-4697-81c2-aa9340b50cf2'
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P1D'
                  isOptional: true
                }
                {
                  name: 'DashboardId'
                  isOptional: true
                }
                {
                  name: 'DraftRequestParameters'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: 'requests\n| where customDimensions[\'faas.name\'] != \'\' or customDimensions[\'Category\'] == \'Host.Results\'\n| extend functionName = tostring(coalesce(customDimensions[\'faas.name\'], name))\n| summarize \n    success=countif(success==true), \n    lastSuccess=maxif(timestamp, success==true),\n    failed=countif(success==false), \n    lastFailure=maxif(timestamp, success==false)\n  by functionName, cloud_RoleName\n| project \n    functionName, \n    lastFailure, \n    failed, \n    lastSuccess, \n    success, \n    functionApp = cloud_RoleName\n| sort by lastFailure desc, functionName asc\n'
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'AnalyticsGrid'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: 'Log Analytics'
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: appInsights.name
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  isOptional: true
                }
                {
                  name: 'LegendOptions'
                  isOptional: true
                }
                {
                  name: 'IsQueryContainTimeRange'
                  value: false
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
              settings: {
                content: {
                  GridColumnsWidth: {
                    failed: '75px'
                    functionApp: '200px'
                    functionName: '225px'
                    lastFailure: '138px'
                    lastSuccess: '138px'
                    success: '92px'
                  }
                }
              }
              partHeader: {
                title: 'Azure Functions'
                subtitle: 'Number of failures and successes per function, including the timestamps of the most recent failure and success'
              }
            }
          }
          {
            position: {
              x: 0
              y: 3
              colSpan: 10
              rowSpan: 5
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                }
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      appInsights.id
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: 'b2f975f1-d716-44e9-be3d-866c400a9c37'
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P1D'
                  isOptional: true
                }
                {
                  name: 'DashboardId'
                  isOptional: true
                }
                {
                  name: 'DraftRequestParameters'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: 'let requestFailures = requests\n| where customDimensions["Service Type"] == "API Management"\n| extend Api = tostring(customDimensions["API Name"])\n| extend isClientFailure = success==false and toint(resultCode) between (400 .. 499)\n| extend isServerFailure = success==false and isClientFailure==false\n| summarize \n    lastClientFailure=maxif(timestamp, isClientFailure),\n    lastServerFailure=maxif(timestamp, isServerFailure),\n    lastSuccess=maxif(timestamp, success==true) \n  by Api;\n              \nrequests\n| where customDimensions["Service Type"] == "API Management"\n| extend Api = tostring(customDimensions["API Name"])\n| evaluate pivot(resultCode, count(), Api)\n| join kind=leftouter requestFailures on Api\n| project-away Api1 // Removes duplicate Api name column introduced by join\n| project-reorder Api, lastServerFailure, * desc, lastSuccess, lastClientFailure // This will make sure the higher result codes (e.g. errors) are rendered first\n| sort by lastServerFailure desc, Api asc\n'
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'AnalyticsGrid'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: 'Log Analytics'
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: appInsights.name
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  isOptional: true
                }
                {
                  name: 'LegendOptions'
                  isOptional: true
                }
                {
                  name: 'IsQueryContainTimeRange'
                  value: false
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
              settings: {
                content: {
                  GridColumnsWidth: {
                    '200': '58px'
                    '201': '58px'
                    '202': '58px'
                    '203': '58px'
                    '204': '58px'
                    '400': '58px'
                    '401': '58px'
                    '403': '58px'
                    '404': '58px'
                    '405': '58px'
                    '406': '58px'
                    '408': '58px'
                    '409': '58px'
                    '412': '58px'
                    '413': '58px'
                    '415': '58px'
                    '422': '58px'
                    '429': '58px'
                    '500': '58px'
                    '501': '58px'
                    '502': '58px'
                    '503': '58px'
                    '504': '58px'
                    '0 [not sent in full (see exception telemetries)]': '75px'
                    Api: '125px'
                    lastClientFailure: '138px'
                    lastServerFailure: '138px'
                    lastSuccess: '138px'
                  }
                }
              }
              partHeader: {
                title: 'API Management requests'
                subtitle: 'Number of requests per API and result code, including the timestamps of the latest success, server-side failure, and client-side failure'
              }
            }
          }
          {
            position: {
              x: 18
              y: 3
              colSpan: 9
              rowSpan: 3
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                }
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      appInsights.id
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: '4d398adf-0ce9-4c58-b831-91fa2b90c60d'
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  value: 'P1D'
                  isOptional: true
                }
                {
                  name: 'DashboardId'
                  isOptional: true
                }
                {
                  name: 'DraftRequestParameters'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: 'traces\n| where customDimensions.Category == \'Workflow.Operations.Runs\'\n| where customDimensions.EventName == \'WorkflowRunEnd\'\n| extend workflow = operation_Name\n| extend status = replace_string(tostring(customDimensions.status), @\'"\', \'\')\n| summarize \n    succeeded=countif(status==\'Succeeded\'),\n    lastSucceeded=maxif(timestamp, status==\'Succeeded\'),\n    failed=countif(status==\'Failed\'),\n    lastFailure=maxif(timestamp, status==\'Failed\'),\n    cancelled=countif(status==\'Cancelled\'),\n    lastCancelled=maxif(timestamp, status==\'Cancelled\')\n  by workflow\n| sort by lastFailure desc, workflow asc\n| project\n    workflow,\n    lastFailure,\n    failed,\n    cancelled,\n    succeeded,\n    lastSucceeded,\n    lastCancelled\n'
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'AnalyticsGrid'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: 'Log Analytics'
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: appInsights.name
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  isOptional: true
                }
                {
                  name: 'LegendOptions'
                  isOptional: true
                }
                {
                  name: 'IsQueryContainTimeRange'
                  value: false
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
              settings: {
                content: {
                  GridColumnsWidth: {
                    cancelled: '97px'
                    failed: '75px'
                    lastCancelled: '138px'
                    lastFailure: '138px'
                    lastSuccess: '138px'
                    logicApp: '200px'
                    running: '82px'
                    succeeded: '102px'
                    workflow: '225px'
                  }
                  Query: 'let runEvents = traces\n| extend category = tostring(customDimensions["Category"])\n| where category == "Workflow.Operations.Runs"\n| extend eventName = tostring(customDimensions["EventName"])\n| extend runId = tostring(parse_json(tostring(customDimensions["resource"]))["runId"]);\n\nrunEvents\n| where eventName == "WorkflowRunStart"\n| join kind=leftouter (\n    runEvents\n    | where eventName == "WorkflowRunEnd"\n  ) on operation_Id, runId // The runId identifies a unique workflow run, the operation_Id alone is not enough\n| extend status = iif(isempty(customDimensions1["status"]), "Running", replace_string(tostring(customDimensions1["status"]), @\'"\', \'\'))\n| summarize\n    succeeded = countif(status == \'Succeeded\'),\n    lastSucceeded = maxif(timestamp, status == \'Succeeded\'),\n    failed = countif(status == \'Failed\'),\n    lastFailure = maxif(timestamp, status == \'Failed\'),\n    cancelled = countif(status == \'Cancelled\'),\n    lastCancelled = maxif(timestamp, status == \'Cancelled\'),\n    running = countif(status == \'Running\')\n  by operation_Name, cloud_RoleName\n| sort by lastFailure desc, operation_Name asc\n| project\n    workflow = operation_Name,\n    lastFailure,\n    failed,\n    cancelled,\n    succeeded,\n    running,\n    lastSucceeded,\n    lastCancelled,\n    logicApp = cloud_RoleName'
                }
              }
              partHeader: {
                title: 'Logic App workflows'
                subtitle: 'Number of instances per status for each workflow, including the timestamp of the most recent occurrence of each status'
              }
            }
          }
          {
            position: {
              x: 10
              y: 4
              colSpan: 8
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: appInsights.id
                          }
                          name: 'requests/failed'
                          aggregationType: 7
                          namespace: 'microsoft.insights/components'
                          metricVisualization: {
                            displayName: 'Failed requests'
                            resourceDisplayName: appInsights.name
                            color: '#EC008C'
                          }
                        }
                      ]
                      title: 'Failed requests'
                      titleKind: 2
                      visualization: {
                        chartType: 3
                      }
                      openBladeOnClick: {
                        openBlade: true
                        destinationBlade: {
                          bladeName: 'ResourceMenuBlade'
                          parameters: {
                            id: appInsights.id
                            menuid: 'failures'
                          }
                          extensionName: 'HubsExtension'
                          options: {
                            parameters: {
                              id: appInsights.id
                              menuid: 'failures'
                            }
                          }
                        }
                      }
                    }
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: appInsights.id
                          }
                          name: 'requests/failed'
                          aggregationType: 7
                          namespace: 'microsoft.insights/components'
                          metricVisualization: {
                            displayName: 'Failed requests'
                            resourceDisplayName: appInsights.name
                            color: '#EC008C'
                          }
                        }
                      ]
                      title: 'Failed requests'
                      titleKind: 2
                      visualization: {
                        chartType: 3
                        disablePinning: true
                      }
                      openBladeOnClick: {
                        openBlade: true
                        destinationBlade: {
                          bladeName: 'ResourceMenuBlade'
                          parameters: {
                            id: appInsights.id
                            menuid: 'failures'
                          }
                          extensionName: 'HubsExtension'
                          options: {
                            parameters: {
                              id: appInsights.id
                              menuid: 'failures'
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 18
              y: 6
              colSpan: 9
              rowSpan: 3
            }
            metadata: {
              inputs: [
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serviceBusNamespace.id
                          }
                          name: 'ActiveMessages'
                          aggregationType: 3
                          namespace: 'microsoft.servicebus/namespaces'
                          metricVisualization: {
                            displayName: 'Count of active messages in a Queue/Topic.'
                          }
                        }
                      ]
                      title: 'Max Count of active messages in a Queue/Topic for ${serviceBusNamespace.name} by EntityName'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideHoverCard: false
                          hideLabelNames: true
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      grouping: {
                        dimension: 'EntityName'
                        sort: 2
                        top: 10
                      }
                      timespan: {
                        relative: {
                          duration: 86400000
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serviceBusNamespace.id
                          }
                          name: 'ActiveMessages'
                          aggregationType: 3
                          namespace: 'microsoft.servicebus/namespaces'
                          metricVisualization: {
                            displayName: 'Count of active messages in a Queue/Topic.'
                          }
                        }
                      ]
                      title: 'Max Count of active messages in a Queue/Topic for ${serviceBusNamespace.name} by EntityName'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideHoverCard: false
                          hideLabelNames: true
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                      grouping: {
                        dimension: 'EntityName'
                        sort: 2
                        top: 10
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: {
              x: 10
              y: 8
              colSpan: 8
              rowSpan: 4
            }
            metadata: {
              inputs: [
                {
                  name: 'resourceTypeMode'
                  isOptional: true
                }
                {
                  name: 'ComponentId'
                  isOptional: true
                }
                {
                  name: 'Scope'
                  value: {
                    resourceIds: [
                      appInsights.id
                    ]
                  }
                  isOptional: true
                }
                {
                  name: 'PartId'
                  value: 'd5cb0d9b-b6fe-4a3b-a47c-486be550308f'
                  isOptional: true
                }
                {
                  name: 'Version'
                  value: '2.0'
                  isOptional: true
                }
                {
                  name: 'TimeRange'
                  isOptional: true
                }
                {
                  name: 'DashboardId'
                  isOptional: true
                }
                {
                  name: 'DraftRequestParameters'
                  isOptional: true
                }
                {
                  name: 'Query'
                  value: 'requests\n| make-series \n    average = avg(duration), \n    median = percentile(duration, 50),\n    p80 = percentile(duration, 80),\n    p95 = percentile(duration, 95),\n    p99 = percentile(duration, 99),\n    default=0\n  on timestamp from ago(15m) to now() step 1m\n| render timechart'
                  isOptional: true
                }
                {
                  name: 'ControlType'
                  value: 'FrameControlChart'
                  isOptional: true
                }
                {
                  name: 'SpecificChart'
                  value: 'Line'
                  isOptional: true
                }
                {
                  name: 'PartTitle'
                  value: 'Log Analytics'
                  isOptional: true
                }
                {
                  name: 'PartSubTitle'
                  value: appInsights.name
                  isOptional: true
                }
                {
                  name: 'Dimensions'
                  value: {
                    xAxis: {
                      name: 'timestamp'
                      type: 'datetime'
                    }
                    yAxis: [
                      {
                        name: 'average'
                        type: 'real'
                      }
                      {
                        name: 'median'
                        type: 'real'
                      }
                      {
                        name: 'p80'
                        type: 'real'
                      }
                      {
                        name: 'p95'
                        type: 'real'
                      }
                    ]
                    splitBy: []
                    aggregation: 'Sum'
                  }
                  isOptional: true
                }
                {
                  name: 'LegendOptions'
                  value: {
                    isEnabled: true
                    position: 'Bottom'
                  }
                  isOptional: true
                }
                {
                  name: 'IsQueryContainTimeRange'
                  value: true
                  isOptional: true
                }
              ]
              type: 'Extension/Microsoft_OperationsManagementSuite_Workspace/PartType/LogsDashboardPart'
              settings: {
                content: {
                  Query: 'requests\n| summarize\n    average = avg(duration),\n    median = percentile(duration, 50),\n    p80 = percentile(duration, 80),\n    p95 = percentile(duration, 95),\n    p99 = percentile(duration, 99)\n  by bin(timestamp, 5m)\n| render timechart\n\n'
                  Dimensions: {
                    xAxis: {
                      name: 'timestamp'
                      type: 'datetime'
                    }
                    yAxis: [
                      {
                        name: 'average'
                        type: 'real'
                      }
                      {
                        name: 'median'
                        type: 'real'
                      }
                      {
                        name: 'p80'
                        type: 'real'
                      }
                      {
                        name: 'p95'
                        type: 'real'
                      }
                      {
                        name: 'p99'
                        type: 'real'
                      }
                    ]
                    splitBy: []
                    aggregation: 'Sum'
                  }
                  IsQueryContainTimeRange: false
                }
              }
              partHeader: {
                title: 'Request duration'
                subtitle: 'Average, median, P80, P95, and P99 request duration, aggregated in 5-minute intervals'
              }
            }
          }
          {
            position: {
              x: 18
              y: 9
              colSpan: 9
              rowSpan: 3
            }
            metadata: {
              inputs: [
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serviceBusNamespace.id
                          }
                          name: 'DeadletteredMessages'
                          aggregationType: 3
                          namespace: 'microsoft.servicebus/namespaces'
                          metricVisualization: {
                            displayName: 'Count of dead-lettered messages in a Queue/Topic.'
                          }
                        }
                      ]
                      title: 'Max Count of dead-lettered messages in a Queue/Topic for ${serviceBusNamespace.name} by EntityName'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideHoverCard: false
                          hideLabelNames: true
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                      }
                      grouping: {
                        dimension: 'EntityName'
                        sort: 2
                        top: 10
                      }
                      timespan: {
                        absolute: {
                          startTime: '2026-09-16T07:53:14.477Z'
                          endTime: '2026-09-16T10:08:42.417Z'
                        }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
              ]
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: serviceBusNamespace.id
                          }
                          name: 'DeadletteredMessages'
                          aggregationType: 3
                          namespace: 'microsoft.servicebus/namespaces'
                          metricVisualization: {
                            displayName: 'Count of dead-lettered messages in a Queue/Topic.'
                          }
                        }
                      ]
                      title: 'Max Count of dead-lettered messages in a Queue/Topic for ${serviceBusNamespace.name} by EntityName'
                      titleKind: 1
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideHoverCard: false
                          hideLabelNames: true
                        }
                        axisVisualization: {
                          x: {
                            isVisible: true
                            axisType: 2
                          }
                          y: {
                            isVisible: true
                            axisType: 1
                          }
                        }
                        disablePinning: true
                      }
                      grouping: {
                        dimension: 'EntityName'
                        sort: 2
                        top: 10
                      }
                    }
                  }
                }
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 24
              timeUnit: 1
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
        filterLocale: {
          value: 'en-us'
        }
        filters: {
          value: {
            MsPortalFx_TimeRange: {
              model: {
                format: 'local'
                granularity: 'auto'
                relative: '4h'
              }
              displayCache: {
                name: 'Local Time'
                value: 'Past 4 hours'
              }
              filteredPartIds: [
                'StartboardPart-MonitorChartPart-18d2dd69-b87f-40d8-a310-9e20401f3093'
                'StartboardPart-LogsDashboardPart-18d2dd69-b87f-40d8-a310-9e20401f3095'
                'StartboardPart-LogsDashboardPart-18d2dd69-b87f-40d8-a310-9e20401f3097'
                'StartboardPart-LogsDashboardPart-18d2dd69-b87f-40d8-a310-9e20401f3099'
                'StartboardPart-MonitorChartPart-18d2dd69-b87f-40d8-a310-9e20401f309b'
                'StartboardPart-MonitorChartPart-18d2dd69-b87f-40d8-a310-9e20401f309d'
                'StartboardPart-LogsDashboardPart-18d2dd69-b87f-40d8-a310-9e20401f309f'
                'StartboardPart-MonitorChartPart-18d2dd69-b87f-40d8-a310-9e20401f30a1'
              ]
            }
          }
        }
      }
    }
  }
}
