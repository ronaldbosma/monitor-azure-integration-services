//=============================================================================
// Monitor Azure Integration Services - Application layer
//=============================================================================

targetScope = 'subscription'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the resource group in which to deploy the resources')
param resourceGroupName string

@description('The name of the API Management service')
param apiManagementServiceName string

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('The name of the Storage Account')
param storageAccountName string

//=============================================================================
// Resources
//=============================================================================

module serviceBusEntities 'modules/service-bus-entities.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
  }
}

module storage 'modules/storage.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    storageAccountName: storageAccountName
  }
}

module apis 'modules/apis/apis.bicep' = {
  scope: resourceGroup(resourceGroupName)
  params: {
    apiManagementServiceName: apiManagementServiceName
  }
  dependsOn: [
    serviceBusEntities
    storage
  ]
}
