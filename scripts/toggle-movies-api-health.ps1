<#
.SYNOPSIS
    Breaks or fixes the health of the Movies API in API Management.

.DESCRIPTION
    Toggles the connection from the Movies API to Table Storage by (mis)configuring
    the URL of the 'table-storage' backend using the Azure CLI.

    If the current URL contains 'broken', the URL is restored to the table storage endpoint.
    Otherwise, the URL is changed to the table storage endpoint suffixed with '/broken',
    which breaks the connection to the movies table.

    When the Movies API is unhealthy:
    - all requests to the Movies API will fail.
    - the Logic App becomes unhealthy because it verifies the health of the Movies API during its health check.

    Asks for confirmation before changing the backend URL. Only 'y' or 'yes' confirms the change.

    When using azd exec, pass --interactive to allow confirmation input.
    Missing confirmation input is rejected without changing the backend.

    The logged in user needs permission to read and update the API Management backend.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER ResourceGroupName
    The name of the resource group. Defaults to the AZURE_RESOURCE_GROUP environment variable.

.PARAMETER ApiManagementName
    The name of the API Management service. Defaults to the AZURE_API_MANAGEMENT_NAME environment variable.

.PARAMETER StorageAccountTableEndpoint
    The table storage endpoint. Defaults to the AZURE_STORAGE_ACCOUNT_TABLE_ENDPOINT environment variable.

.EXAMPLE
    azd exec --interactive ./toggle-movies-api-health.ps1

    Prompts to break or fix the Movies API health using the environment variables of the current azd environment.

.EXAMPLE
    ./toggle-movies-api-health.ps1 -SubscriptionId '<subscription-id>' `
        -ResourceGroupName 'rg-monitorais-frc-u7eei' -ApiManagementName 'apim-monitorais-frc-u7eei' `
        -StorageAccountTableEndpoint 'https://stmonitoraisfrcu7eei.table.core.windows.net/'

    Runs the script directly with explicitly specified values.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroupName = $env:AZURE_RESOURCE_GROUP,
    [string]$ApiManagementName = $env:AZURE_API_MANAGEMENT_NAME,
    [string]$StorageAccountTableEndpoint = $env:AZURE_STORAGE_ACCOUNT_TABLE_ENDPOINT
)

$ErrorActionPreference = 'Stop'

$backendId = 'table-storage'

# Validate required parameters
$requiredParameters = @{
    SubscriptionId              = $SubscriptionId
    ResourceGroupName           = $ResourceGroupName
    ApiManagementName           = $ApiManagementName
    StorageAccountTableEndpoint = $StorageAccountTableEndpoint
}
$missingParameters = $requiredParameters.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace($_.Value) } | ForEach-Object { $_.Key }
if ($missingParameters) {
    throw "The following parameters are not specified and have no environment variable value: $($missingParameters -join ', '). Specify them explicitly or run the script using 'azd exec'."
}

# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}

# Retrieve the current backend URL
$currentValue = az apim backend show --service-name $ApiManagementName --resource-group $ResourceGroupName `
    --backend-id $backendId --query url --output tsv
if ($LASTEXITCODE -ne 0) {
    throw "Unable to retrieve backend '$backendId' of API Management service '$ApiManagementName' in resource group '$ResourceGroupName'."
}
if ([string]::IsNullOrWhiteSpace($currentValue)) {
    throw "Backend '$backendId' of API Management service '$ApiManagementName' has no URL. No backend change was performed."
}

Write-Host "Backend '$backendId' of API Management service '$ApiManagementName' in resource group '$ResourceGroupName' currently has URL '$currentValue'."

# Determine the action to perform based on the current value
if ($currentValue -like '*broken*') {
    $action = 'Fix'
    $newValue = $StorageAccountTableEndpoint
}
else {
    $action = 'Break'
    $newValue = "$($StorageAccountTableEndpoint.TrimEnd('/'))/broken"
}

# Confirm the action with the user
$confirmation = Read-Host "$action the health of the Movies API by setting backend '$backendId' URL to '$newValue'? [y/N]"
if ($null -eq $confirmation) {
    throw "No confirmation input is available. No backend change was performed. When using 'azd exec', pass '--interactive' to enable confirmation input."
}
if ($confirmation.Trim() -notin @('y', 'yes')) {
    Write-Host 'Backend change cancelled.'
    return
}

# Update the backend URL
Write-Host "Setting backend '$backendId' URL of API Management service '$ApiManagementName' to '$newValue'"

az apim backend update --service-name $ApiManagementName --resource-group $ResourceGroupName `
    --backend-id $backendId --url $newValue --output none
if ($LASTEXITCODE -ne 0) {
    throw "Unable to update backend '$backendId' of API Management service '$ApiManagementName' in resource group '$ResourceGroupName'."
}

Write-Host 'Backend URL updated. It might take a few seconds before the change takes effect.'
