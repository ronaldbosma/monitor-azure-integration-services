<#
.SYNOPSIS
    Publishes an invalid message to the recalculate-movie-rating queue of the Service Bus namespace.

.DESCRIPTION
    Sends the JSON message `{ 'id': 'invalid-id' }` to the recalculate-movie-rating queue using the Service Bus REST API.
    This will result in a failed Logic App workflow run.

    The message is sent with 'az rest', so the logged in user needs the 'Azure Service Bus Data Sender' role
    on the Service Bus namespace.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER ServiceBusNamespaceEndpoint
    The endpoint of the Service Bus namespace (e.g. https://sbns-monitorais-frc-u7eei.servicebus.windows.net:443/).
    Defaults to the AZURE_SERVICE_BUS_NAMESPACE_ENDPOINT environment variable.

.EXAMPLE
    azd exec ./publish-invalid-recalculate-movie-rating-message.ps1

    Runs the script with the environment variables of the current azd environment.

.EXAMPLE
    ./publish-invalid-recalculate-movie-rating-message.ps1 -SubscriptionId '<subscription-id>' -ServiceBusNamespaceEndpoint 'https://sbns-monitorais-frc-u7eei.servicebus.windows.net:443/'

    Runs the script directly with explicitly specified values.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ServiceBusNamespaceEndpoint = $env:AZURE_SERVICE_BUS_NAMESPACE_ENDPOINT
)

$ErrorActionPreference = 'Stop'

# Validate required parameters
$requiredParameters = @{
    SubscriptionId              = $SubscriptionId
    ServiceBusNamespaceEndpoint = $ServiceBusNamespaceEndpoint
}
$missingParameters = $requiredParameters.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace($_.Value) } | ForEach-Object { $_.Key }
if ($missingParameters) {
    throw "The following parameters are not specified and have no environment variable value: $($missingParameters -join ', '). Specify them explicitly or run the script using 'azd exec'."
}

# Publish message to recalculate-movie-rating queue
$messageParameters = @{
    SubscriptionId              = $SubscriptionId
    ServiceBusNamespaceEndpoint = $ServiceBusNamespaceEndpoint
    EntityType                  = 'Queue'
    EntityName                  = 'recalculate-movie-rating'
    Message                     = "{ 'id': 'invalid-id' }"
}
& (Join-Path $PSScriptRoot 'shared\publish-service-bus-message.ps1') @messageParameters
