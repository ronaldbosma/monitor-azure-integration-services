<#
.SYNOPSIS
    Starts or stops the Azure Logic App.

.DESCRIPTION
    Retrieves the current state and asks for confirmation before starting or stopping
    the Logic App using the Azure CLI. Only 'y' or 'yes' confirms the change.
    A running Logic App is stopped; a stopped Logic App is started.
    Other states are rejected without changing the Logic App.

    When using azd exec, pass --interactive to allow confirmation input.
    Missing confirmation input is rejected without changing the Logic App.

    The logged in user needs permission to start and stop the Logic App.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER ResourceGroupName
    The name of the resource group. Defaults to the AZURE_RESOURCE_GROUP environment variable.

.PARAMETER LogicAppName
    The name of the Logic App. Defaults to the AZURE_LOGIC_APP_NAME environment variable.

.EXAMPLE
    azd exec --interactive ./toggle-logic-app-state.ps1

    Prompts to toggle the Logic App state using the environment variables of the current azd environment.

.EXAMPLE
    ./toggle-logic-app-state.ps1 -SubscriptionId '<subscription-id>' `
        -ResourceGroupName 'rg-monitorais-sdc-45gou' -LogicAppName 'logic-monitorais-sdc-45gou'

    Runs the script directly with explicitly specified values.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroupName = $env:AZURE_RESOURCE_GROUP,
    [string]$LogicAppName = $env:AZURE_LOGIC_APP_NAME
)

$ErrorActionPreference = 'Stop'

# Validate required parameters
$requiredParameters = @{
    SubscriptionId    = $SubscriptionId
    ResourceGroupName = $ResourceGroupName
    LogicAppName      = $LogicAppName
}
$missingParameters = $requiredParameters.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace($_.Value) } | ForEach-Object { $_.Key }
if ($missingParameters) {
    throw "The following parameters are not specified and have no environment variable value: $($missingParameters -join ', '). Specify them explicitly or run the script using 'azd exec'."
}

# Toggle the Logic App state
$toggleParameters = @{
    SubscriptionId     = $SubscriptionId
    ResourceGroupName  = $ResourceGroupName
    WebAppName         = $LogicAppName
    AppTypeDisplayName = 'Logic App'
}
& (Join-Path $PSScriptRoot 'shared\toggle-web-app-state.ps1') @toggleParameters
