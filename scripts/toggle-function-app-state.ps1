<#
.SYNOPSIS
    Starts or stops the Azure Function App.

.DESCRIPTION
    Retrieves the current state and asks for confirmation before starting or stopping
    the Function App using the Azure CLI. Only 'y' or 'yes' confirms the change.
    A running Function App is stopped; a stopped Function App is started.
    Other states are rejected without changing the Function App.

    When using azd exec, pass --interactive to allow confirmation input.
    Missing confirmation input is rejected without changing the Function App.

    The logged in user needs permission to start and stop the Function App.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER ResourceGroupName
    The name of the resource group. Defaults to the AZURE_RESOURCE_GROUP environment variable.

.PARAMETER FunctionAppName
    The name of the Function App. Defaults to the AZURE_FUNCTION_APP_NAME environment variable.

.EXAMPLE
    azd exec --interactive ./toggle-function-app-state.ps1

    Prompts to toggle the Function App state using the environment variables of the current azd environment.

.EXAMPLE
    ./toggle-function-app-state.ps1 -SubscriptionId '<subscription-id>' `
        -ResourceGroupName 'rg-monitorais-sdc-45gou' -FunctionAppName 'func-monitorais-sdc-45gou'

    Runs the script directly with explicitly specified values.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroupName = $env:AZURE_RESOURCE_GROUP,
    [string]$FunctionAppName = $env:AZURE_FUNCTION_APP_NAME
)

$ErrorActionPreference = 'Stop'

# Validate required parameters
$requiredParameters = @{
    SubscriptionId    = $SubscriptionId
    ResourceGroupName = $ResourceGroupName
    FunctionAppName   = $FunctionAppName
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

# Retrieve the current state of the Function App
$currentState = az functionapp show --name $FunctionAppName --resource-group $ResourceGroupName --query state --output tsv
if ($LASTEXITCODE -ne 0) {
    throw "Unable to retrieve the current state of Function App '$FunctionAppName' in resource group '$ResourceGroupName'."
}
if ([string]::IsNullOrWhiteSpace($currentState)) {
    throw "No current state was returned for Function App '$FunctionAppName' in resource group '$ResourceGroupName'."
}

# Determine the action to perform based on the current state
Write-Host "Function App '$FunctionAppName' in resource group '$ResourceGroupName' is currently '$currentState'."
$action = switch ($currentState) {
    'Running' { 'Stop' }
    'Stopped' { 'Start' }
    default { throw "Cannot toggle Function App '$FunctionAppName' while its state is '$currentState'. Expected 'Running' or 'Stopped'." }
}

# Confirm the action with the user
$confirmation = Read-Host "Perform '$action' on this Function App? [y/N]"
if ($null -eq $confirmation) {
    throw "No confirmation input is available. No state change was performed. When using 'azd exec', run 'azd exec --interactive ./toggle-function-app-state.ps1' to enable confirmation input."
}
if ($confirmation.Trim() -notin @('y', 'yes')) {
    Write-Host 'State change cancelled.'
    return
}

# Perform the action on the Function App
Write-Host "Performing '$action' on Function App '$FunctionAppName' in resource group '$ResourceGroupName'"

az functionapp $action.ToLowerInvariant() --name $FunctionAppName --resource-group $ResourceGroupName --output none
if ($LASTEXITCODE -ne 0) {
    throw "Unable to $($action.ToLowerInvariant()) Function App '$FunctionAppName' in resource group '$ResourceGroupName'."
}
