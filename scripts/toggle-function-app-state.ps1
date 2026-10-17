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
        -ResourceGroupName 'rg-monitorais-frc-u7eei' -FunctionAppName 'func-monitorais-frc-u7eei'

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

# Toggle the Function App state
$toggleParameters = @{
    SubscriptionId     = $SubscriptionId
    ResourceGroupName  = $ResourceGroupName
    WebAppName         = $FunctionAppName
    AppTypeDisplayName = 'Function App'
}
& (Join-Path $PSScriptRoot 'shared\toggle-web-app-state.ps1') @toggleParameters
