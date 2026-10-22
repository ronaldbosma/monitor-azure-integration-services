<#
.SYNOPSIS
    Starts or stops a web app, like a Function App or Logic App (Standard).

.DESCRIPTION
    Retrieves the current state and asks for confirmation before starting or stopping
    the web app using the Azure CLI. Only 'y' or 'yes' confirms the change.
    A running web app is stopped; a stopped web app is started.
    Other states are rejected without changing the web app.

    Missing confirmation input is rejected without changing the web app.

.PARAMETER SubscriptionId
    The id of the Azure subscription.

.PARAMETER ResourceGroupName
    The name of the resource group.

.PARAMETER WebAppName
    The name of the web app.

.PARAMETER AppTypeDisplayName
    The type of app used in messages, e.g. 'Function App' or 'Logic App'. Defaults to 'Web App'.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SubscriptionId,
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,
    [Parameter(Mandatory)]
    [string]$WebAppName,
    [string]$AppTypeDisplayName = 'Web App'
)

$ErrorActionPreference = 'Stop'

# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}

# Retrieve the current state of the web app
$currentState = az webapp show --name $WebAppName --resource-group $ResourceGroupName --query state --output tsv
if ($LASTEXITCODE -ne 0) {
    throw "Unable to retrieve the current state of $AppTypeDisplayName '$WebAppName' in resource group '$ResourceGroupName'."
}
if ([string]::IsNullOrWhiteSpace($currentState)) {
    throw "No current state was returned for $AppTypeDisplayName '$WebAppName' in resource group '$ResourceGroupName'."
}

# Determine the action to perform based on the current state
Write-Host "$AppTypeDisplayName '$WebAppName' in resource group '$ResourceGroupName' is currently '$currentState'."
$action = switch ($currentState) {
    'Running' { 'Stop' }
    'Stopped' { 'Start' }
    default { throw "Cannot toggle $AppTypeDisplayName '$WebAppName' while its state is '$currentState'. Expected 'Running' or 'Stopped'." }
}

# Confirm the action with the user
$confirmation = Read-Host "Perform '$action' on this $($AppTypeDisplayName)? [y/N]"
if ($null -eq $confirmation) {
    throw "No confirmation input is available. No state change was performed. When using 'azd exec', pass '--interactive' to enable confirmation input."
}
if ($confirmation.Trim() -notin @('y', 'yes')) {
    Write-Host 'State change cancelled.'
    return
}

# Perform the action on the web app
Write-Host "Performing '$action' on $AppTypeDisplayName '$WebAppName' in resource group '$ResourceGroupName'"

az webapp $action.ToLowerInvariant() --name $WebAppName --resource-group $ResourceGroupName --output none
if ($LASTEXITCODE -ne 0) {
    throw "Unable to $($action.ToLowerInvariant()) $AppTypeDisplayName '$WebAppName' in resource group '$ResourceGroupName'."
}
