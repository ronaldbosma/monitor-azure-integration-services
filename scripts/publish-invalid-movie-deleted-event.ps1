<#
.SYNOPSIS
    Publishes an invalid movie deleted event message to the deleted-movies topic of the Service Bus namespace.

.DESCRIPTION
    Sends the JSON message { "id": "invalid-id" } to the deleted-movies topic using the Service Bus REST API.
    This will result in a failed Azure Functions execution and the message being dead-lettered in the Service Bus topic.

    The message is sent with 'az rest', so the logged in user needs the 'Azure Service Bus Data Sender' role
    on the Service Bus namespace.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER ServiceBusNamespaceName
    The name of the Service Bus namespace. Defaults to the AZURE_SERVICE_BUS_NAMESPACE_NAME environment variable.

.EXAMPLE
    azd exec ./publish-invalid-movie-deleted-event.ps1

    Runs the script with the environment variables of the current azd environment.

.EXAMPLE
    ./publish-invalid-movie-deleted-event.ps1 -SubscriptionId '<subscription-id>' -ServiceBusNamespaceName 'sbns-monitorais-sdc-45gou'

    Runs the script directly with explicitly specified values.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ServiceBusNamespaceName = $env:AZURE_SERVICE_BUS_NAMESPACE_NAME
)

$ErrorActionPreference = 'Stop'

# Validate required parameters
$requiredParameters = @{
    SubscriptionId          = $SubscriptionId
    ServiceBusNamespaceName = $ServiceBusNamespaceName
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

# Publish the message to the deleted-movies topic of the Service Bus namespace
$topicName = 'deleted-movies'
$uri = "https://$ServiceBusNamespaceName.servicebus.windows.net/$topicName/messages"
$message = '{ "id": "invalid-id" }'

Write-Host "Sending message $message to topic '$topicName' of Service Bus namespace '$ServiceBusNamespaceName'"

az rest --method post --uri $uri --resource 'https://servicebus.azure.net' `
        --headers 'Content-Type=application/json' --body $message --output none
if ($LASTEXITCODE -ne 0) {
    throw "Unable to send the message to topic '$topicName' of Service Bus namespace '$ServiceBusNamespaceName'."
}
