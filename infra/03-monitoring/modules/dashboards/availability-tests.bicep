//=============================================================================
// Availability Tests
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { getResourceName } from '../../../99-shared/naming-conventions.bicep'
import * as helpers from '../../../99-shared/helpers.bicep'
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
// Variables
//=============================================================================

var apimStatusEndpointAvailabilityTestName string = getResourceName('webtest', environmentName, location, 'apimstatus')

//=============================================================================
// Existing resources
//=============================================================================

resource apiManagementService 'Microsoft.ApiManagement/service@2025-09-01-preview' existing = {
  name: apiManagementServiceName
}


resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

//=============================================================================
// Resources
//=============================================================================

resource apimStatusEndpointAvailabilityTest 'Microsoft.Insights/webtests@2022-06-15' = {
  name: apimStatusEndpointAvailabilityTestName
  location: location
  tags: union(tags, {
    'hidden-link:${appInsights.id}': 'Resource'
  })

  properties: {
    Name: 'API Management status endpoint' // This name will be displayed in the availability test overview in the Azure portal
    Description: 'Status of the API Management service'
    SyntheticMonitorId: 'API Management status endpoint'

    Kind: 'standard'
    Enabled: true
    RetryEnabled: false // Set to false for this demo to reduce the number of failed calls

    // A frequence of 300 means that every 5 minutes the test will execute from all configured locations.
    // So if you have 5 locations, the test will run 5 times every 5 minutes.
    // Note that the test will not run exactly every minute.
    Frequency: 300

    // For a list of available locations, see: https://learn.microsoft.com/en-us/previous-versions/azure/azure-monitor/app/monitor-web-app-availability#location-population-tags
    Locations: [
      {
        Id: 'emea-nl-ams-azr' // West Europe
      }
      {
        Id: 'emea-gb-db3-azr' // North Europe
      }
      {
        Id: 'emea-ru-msa-edge' // UK South
      }
      {
        Id: 'emea-fr-pra-edge' // France Central
      }
      {
        Id: 'emea-ch-zrh-edge' // France South
      }
    ]

    Request: {
      HttpVerb: 'GET'
      RequestUrl: '${helpers.getApiManagementGatewayUrl(apiManagementServiceName)}/${helpers.getApiManagementStatusEndpoint(apiManagementService.sku.name)}'
    }

    ValidationRules: {
      ExpectedHttpStatusCode: 200
      IgnoreHttpStatusCode: false
      SSLCheck: false // A separate test will check the SSL certificate of the API Management service
    }
  }
}
