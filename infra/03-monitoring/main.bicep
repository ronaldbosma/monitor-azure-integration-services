//=============================================================================
// Monitor Azure Integration Services - Monitoring layer
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Imports
//=============================================================================

import { getTemplateTags } from '../99-shared/helpers.bicep'
import { tagsType } from '../99-shared/types.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the environment to deploy to')
param environmentName string

@description('Location to use for all resources')
param location string

@description('The name of the resource group in which to deploy the resources')
param resourceGroupName string

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The name of the App Insights instance')
param appInsightsName string

@description('The name of the Function App')
param functionAppName string

@description('The name of the Logic App')
param logicAppName string

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

//=============================================================================
// Variables
//=============================================================================

var tags tagsType = getTemplateTags(environmentName)

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apiManagementServiceName
  scope: resourceGroup(resourceGroupName)
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
  scope: resourceGroup(resourceGroupName)
}

//=============================================================================
// Resources
//=============================================================================

module availabilityTests './modules/availability-tests.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    apiManagementServiceName: apiManagementServiceName
    appInsightsName: appInsightsName
  }
}

module dashboards './modules/dashboards.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    appInsightsName: appInsightsName
    functionAppName: functionAppName
    logicAppName: logicAppName
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

// Alerts

module deadLetteredMessagesAlert './modules/alerts/deadlettered-messages-alert.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module failedApimRequestsAlert './modules/alerts/failed-apim-requests-alert.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    apiManagementServiceName: apiManagementServiceName
    appInsightsName: appInsightsName
  }
}

module failedAvailabilityTestAlert './modules/alerts/failed-availability-test-alert.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    appInsightsName: appInsightsName
  }
}

module failedFunctionAlert './modules/alerts/failed-function-alert.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    appInsightsName: appInsightsName
    functionAppName: functionAppName
  }
}

module failedWorkflowAlert './modules/alerts/failed-workflow-alert.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    appInsightsName: appInsightsName
    logicAppName: logicAppName
  }
}

module functionAppHealthCheckStatusAlert './modules/alerts/health-check-status-alert.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    siteName: functionAppName
    siteNameShort: 'functionapp'
  }
}

module logicAppHealthCheckStatusAlert './modules/alerts/health-check-status-alert.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    siteName: logicAppName
    siteNameShort: 'logicapp'
  }
}

module recalculateRatingForAllMoviesWorkflowNotStartedAlert './modules/alerts/recalculate-ratings-workflow-not-started-alert.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    logicAppName: logicAppName
  }
}

// Workbooks

module apimRequestsWorkbook './modules/workbooks/workbook.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    displayName: 'APIM Requests'
    serializedData: string(loadJsonContent('./modules/workbooks/APIM Requests.workbook'))
    placeholders: {
      AzureSubscriptionId: subscription().subscriptionId
      ApplicationInsightsId: appInsights.id
    }
    sourceId: appInsights.id
  }
}

module apimInsightsWorkbook './modules/workbooks/workbook.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    displayName: 'APIM Insights'
    serializedData: string(loadJsonContent('./modules/workbooks/APIM Insights.workbook'))
    placeholders: {
      AzureSubscriptionId: subscription().subscriptionId
      ApplicationInsightsId: appInsights.id
      ApiManagementId: apiManagementService.id
    }
    sourceId: appInsights.id
  }
}

module azureFunctionsWorkbook './modules/workbooks/workbook.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    displayName: 'Azure Functions'
    serializedData: string(loadJsonContent('./modules/workbooks/Azure Functions.workbook'))
    placeholders: {
      AzureSubscriptionId: subscription().subscriptionId
      ApplicationInsightsId: appInsights.id
    }
    sourceId: appInsights.id
  }
}

module logicAppWorkflowsWorkbook './modules/workbooks/workbook.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    displayName: 'Logic App Workflows'
    serializedData: string(loadJsonContent('./modules/workbooks/Logic App Workflows.workbook'))
    placeholders: {
      AzureSubscriptionId: subscription().subscriptionId
      ApplicationInsightsId: appInsights.id
    }
    sourceId: appInsights.id
  }
}
