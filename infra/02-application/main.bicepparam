using './main.bicep'

param resourceGroupName = readEnvironmentVariable('AZURE_RESOURCE_GROUP')
param apiManagementServiceName =  readEnvironmentVariable('AZURE_API_MANAGEMENT_NAME')
param functionAppName = readEnvironmentVariable('AZURE_FUNCTION_APP_NAME')
param keyVaultName = readEnvironmentVariable('AZURE_KEY_VAULT_NAME')
param serviceBusNamespaceName = readEnvironmentVariable('AZURE_SERVICE_BUS_NAMESPACE_NAME')
param storageAccountName = readEnvironmentVariable('AZURE_STORAGE_ACCOUNT_NAME')
