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
