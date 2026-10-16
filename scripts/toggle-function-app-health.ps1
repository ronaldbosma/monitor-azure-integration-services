<#
.SYNOPSIS
    Breaks or fixes the health of the Azure Function App (and User Ratings API).

.DESCRIPTION
    Toggles the connection from the Function App to the user ratings table by (mis)configuring
    the StorageAccountConnection__tableServiceUri app setting using the Azure CLI.

    If the current value contains 'broken', the setting is restored to the table storage endpoint.
    Otherwise, the setting is changed to the table storage endpoint suffixed with '/broken',
    which breaks the connection to the user ratings table.

    Changing the app setting restarts the Function App, so it might take a moment before the health actually changes.

    Asks for confirmation before changing the app setting. Only 'y' or 'yes' confirms the change.

    When using azd exec, pass --interactive to allow confirmation input.
    Missing confirmation input is rejected without changing the Function App.

    The logged in user needs permission to read and update the app settings of the Function App.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER ResourceGroupName
    The name of the resource group. Defaults to the AZURE_RESOURCE_GROUP environment variable.

.PARAMETER FunctionAppName
    The name of the Function App. Defaults to the AZURE_FUNCTION_APP_NAME environment variable.

.PARAMETER StorageAccountTableEndpoint
    The table storage endpoint. Defaults to the AZURE_STORAGE_ACCOUNT_TABLE_ENDPOINT environment variable.

.EXAMPLE
    azd exec --interactive ./toggle-function-app-health.ps1

    Prompts to break or fix the Function App health using the environment variables of the current azd environment.

.EXAMPLE
    ./toggle-function-app-health.ps1 -SubscriptionId '<subscription-id>' `
        -ResourceGroupName 'rg-monitorais-sdc-45gou' -FunctionAppName 'func-monitorais-sdc-45gou' `
        -StorageAccountTableEndpoint 'https://stmonitoraissdc45gou.table.core.windows.net/'

    Runs the script directly with explicitly specified values.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroupName = $env:AZURE_RESOURCE_GROUP,
    [string]$FunctionAppName = $env:AZURE_FUNCTION_APP_NAME,
    [string]$StorageAccountTableEndpoint = $env:AZURE_STORAGE_ACCOUNT_TABLE_ENDPOINT
)

$ErrorActionPreference = 'Stop'

$appSettingName = 'StorageAccountConnection__tableServiceUri'

# Validate required parameters
$requiredParameters = @{
    SubscriptionId              = $SubscriptionId
    ResourceGroupName           = $ResourceGroupName
    FunctionAppName             = $FunctionAppName
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

# Retrieve the current value of the table service URI app setting
$currentValue = az webapp config appsettings list --name $FunctionAppName --resource-group $ResourceGroupName `
    --query "[?name=='$appSettingName'].value | [0]" --output tsv
if ($LASTEXITCODE -ne 0) {
    throw "Unable to retrieve the app settings of Function App '$FunctionAppName' in resource group '$ResourceGroupName'."
}

Write-Host "App setting '$appSettingName' of Function App '$FunctionAppName' in resource group '$ResourceGroupName' is currently '$currentValue'."

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
$confirmation = Read-Host "$action the health of this Function App by setting '$appSettingName' to '$newValue'? [y/N]"
if ($null -eq $confirmation) {
    throw "No confirmation input is available. No app setting change was performed. When using 'azd exec', pass '--interactive' to enable confirmation input."
}
if ($confirmation.Trim() -notin @('y', 'yes')) {
    Write-Host 'App setting change cancelled.'
    return
}

# Update the app setting
Write-Host "Setting '$appSettingName' of Function App '$FunctionAppName' to '$newValue'"

az webapp config appsettings set --name $FunctionAppName --resource-group $ResourceGroupName `
    --settings "$appSettingName=$newValue" --output none
if ($LASTEXITCODE -ne 0) {
    throw "Unable to update app setting '$appSettingName' of Function App '$FunctionAppName' in resource group '$ResourceGroupName'."
}

Write-Host "App setting updated. It might take a moment for the Function App to restart and the health to change."
