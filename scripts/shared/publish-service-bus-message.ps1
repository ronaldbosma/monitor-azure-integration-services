<#
.SYNOPSIS
    Publishes a message to a Service Bus topic or queue.

.PARAMETER SubscriptionId
    The id of the Azure subscription.

.PARAMETER ServiceBusNamespaceEndpoint
    The endpoint of the Service Bus namespace.

.PARAMETER EntityType
    The Service Bus entity type: Topic or Queue.

.PARAMETER EntityName
    The name of the Service Bus topic or queue.

.PARAMETER Message
    The message body to publish.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$ServiceBusNamespaceEndpoint,
    [ValidateSet('Topic', 'Queue')]
    [string]$EntityType,
    [string]$EntityName,
    [string]$Message
)

$ErrorActionPreference = 'Stop'

# Validate that all required parameters are specified
$requiredParameters = @{
    SubscriptionId              = $SubscriptionId
    ServiceBusNamespaceEndpoint = $ServiceBusNamespaceEndpoint
    EntityType                  = $EntityType
    EntityName                  = $EntityName
    Message                     = $Message
}
$missingParameters = $requiredParameters.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace($_.Value) } | ForEach-Object { $_.Key }
if ($missingParameters) {
    throw "The following parameters are not specified: $($missingParameters -join ', ')."
}

# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}

# Construct the URI for the Service Bus entity based on the entity type and name
$entityTypeName = $EntityType.ToLowerInvariant()
$uri = "$($ServiceBusNamespaceEndpoint.TrimEnd('/'))/$EntityName/messages"

Write-Host "Sending message $Message to $entityTypeName '$EntityName' of Service Bus namespace '$ServiceBusNamespaceEndpoint'"

# Send the message to the Service Bus entity using the Azure REST API
az rest --method post --uri $uri --resource 'https://servicebus.azure.net' `
        --headers 'Content-Type=application/json' --body $Message --output none
if ($LASTEXITCODE -ne 0) {
    throw "Unable to send the message to $entityTypeName '$EntityName' of Service Bus namespace '$ServiceBusNamespaceEndpoint'."
}
