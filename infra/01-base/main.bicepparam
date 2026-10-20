using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param location = readEnvironmentVariable('AZURE_LOCATION')
param apiManagementSku = readEnvironmentVariable('AZURE_API_MANAGEMENT_SKU', 'Consumption')
