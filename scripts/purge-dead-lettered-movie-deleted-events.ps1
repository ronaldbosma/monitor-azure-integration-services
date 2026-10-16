<#
.SYNOPSIS
    Purges the dead-lettered messages from the function-app subscription of the deleted-movies topic.

.DESCRIPTION
    Receives and deletes all messages from the dead-letter queue of the function-app subscription
    of the deleted-movies topic using the Service Bus REST API.

    The messages are received with 'az rest', so the logged in user needs the 'Azure Service Bus Data Receiver' role
    on the Service Bus namespace.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER ServiceBusNamespaceEndpoint
    The endpoint of the Service Bus namespace (e.g. https://sbns-monitorais-sdc-45gou.servicebus.windows.net:443/).
    Defaults to the AZURE_SERVICE_BUS_NAMESPACE_ENDPOINT environment variable.

.EXAMPLE
    azd exec ./purge-dead-lettered-movie-deleted-events.ps1

    Runs the script with the environment variables of the current azd environment.

.EXAMPLE
    ./purge-dead-lettered-movie-deleted-events.ps1 -SubscriptionId '<subscription-id>' -ServiceBusNamespaceEndpoint 'https://sbns-monitorais-sdc-45gou.servicebus.windows.net:443/'

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

$topicName = 'deleted-movies'
$subscriptionName = 'function-app'

# First, ensure the Azure CLI is logged in and set to the correct subscription
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) {
    throw "Unable to set the Azure subscription. Please make sure that you're logged into the Azure CLI with the same credentials as the Azure Developer CLI."
}

# Construct the URI to receive and delete the message at the head of the dead-letter queue
$uri = "$($ServiceBusNamespaceEndpoint.TrimEnd('/'))/$topicName/subscriptions/$subscriptionName/`$DeadLetterQueue/messages/head?timeout=5"

Write-Host "Purging dead-lettered messages from subscription '$subscriptionName' of topic '$topicName' of Service Bus namespace '$ServiceBusNamespaceEndpoint'"

# Receive and delete messages until the dead-letter queue is empty.
# The REST API returns 200 OK with the message body, or 204 No Content (empty body) when the queue is empty.
$purgedMessageCount = 0
while ($true) {
    $message = az rest --method delete --uri $uri --resource 'https://servicebus.azure.net'
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to receive and delete dead-lettered message from subscription '$subscriptionName' of topic '$topicName' of Service Bus namespace '$ServiceBusNamespaceEndpoint'."
    }

    if ([string]::IsNullOrWhiteSpace($message)) {
        break
    }

    $purgedMessageCount++
    Write-Host "Purged message $message"
}

Write-Host "Purged $purgedMessageCount dead-lettered message(s)"
