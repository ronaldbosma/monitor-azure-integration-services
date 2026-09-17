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

//=============================================================================
// Variables
//=============================================================================

var tags tagsType = getTemplateTags(environmentName)

//=============================================================================
// Resources
//=============================================================================

module availabilityTests './modules/dashboards/availability-tests.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    apiManagementServiceName: apiManagementServiceName
    appInsightsName: appInsightsName
  }
}
