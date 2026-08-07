//=============================================================================
// Sets up connectivity between the different resources
//=============================================================================

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the API Management Service')
param apiManagementServiceName string

@description('The name of the Function App')
param functionAppName string

@description('The name of the Key Vault that will contain the secrets')
param keyVaultName string

@description('The name of the Logic App')
param logicAppName string

@description('The name of the Service Bus namespace')
param serviceBusNamespaceName string

@description('Name of the storage account that will be used by the Function App')
param storageAccountName string

//=============================================================================
// Resources
//=============================================================================

module apiManagementConnectivity 'api-management-connectivity.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    functionAppName: functionAppName
    keyVaultName: keyVaultName
    serviceBusNamespaceName: serviceBusNamespaceName
    storageAccountName: storageAccountName
  }
}

module functionAppConnectivity 'function-app-connectivity.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    functionAppName: functionAppName
    keyVaultName: keyVaultName
    serviceBusNamespaceName: serviceBusNamespaceName
    storageAccountName: storageAccountName
  }
}

module logicAppConnectivity 'logic-app-connectivity.bicep' = {
  params: {
    apiManagementServiceName: apiManagementServiceName
    keyVaultName: keyVaultName
    logicAppName: logicAppName
    serviceBusNamespaceName: serviceBusNamespaceName
    storageAccountName: storageAccountName
  }
}
