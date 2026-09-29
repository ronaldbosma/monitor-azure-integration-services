using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param location = readEnvironmentVariable('AZURE_LOCATION')
param resourceGroupName = readEnvironmentVariable('AZURE_RESOURCE_GROUP')
param apiManagementServiceName =  readEnvironmentVariable('AZURE_API_MANAGEMENT_NAME')
param appInsightsName =  readEnvironmentVariable('AZURE_APPLICATION_INSIGHTS_NAME')
param functionAppName = readEnvironmentVariable('AZURE_FUNCTION_APP_NAME')
param logicAppName = readEnvironmentVariable('AZURE_LOGIC_APP_NAME')
param serviceBusNamespaceName = readEnvironmentVariable('AZURE_SERVICE_BUS_NAMESPACE_NAME')
