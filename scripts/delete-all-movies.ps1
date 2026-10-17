<#
.SYNOPSIS
    Deletes all movies and related user ratings.

.DESCRIPTION
    Retrieves all movies using the Movies API in API Management and deletes them one by one.
    The integration application removes the user ratings of each deleted movie, effectively
    clearing the storage tables. HTTP requests are performed using 'az rest'.

    The Movies API is protected by an API Management subscription.
    The subscription key is read from the 'tester-apim-subscription-key' secret in Key Vault
    and passed in the 'Ocp-Apim-Subscription-Key' header.

    Asks for confirmation before deleting the movies. Only 'y' or 'yes' confirms the deletion.
    This operation cannot be undone.

    When using azd exec, pass --interactive to allow confirmation input.
    Missing confirmation input is rejected without deleting any movies.

    The logged in user needs permission to read secrets from the Key Vault (e.g. the Key Vault Secrets User role).

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER KeyVaultName
    The name of the Key Vault. Defaults to the AZURE_KEY_VAULT_NAME environment variable.

.PARAMETER ApiManagementGatewayUrl
    The gateway URL of the API Management service. Defaults to the AZURE_API_MANAGEMENT_GATEWAY_URL environment variable.

.EXAMPLE
    azd exec --interactive ./delete-all-movies.ps1

    Prompts to delete all movies using the environment variables of the current azd environment.

.EXAMPLE
    ./delete-all-movies.ps1 -SubscriptionId '<subscription-id>' `
        -KeyVaultName 'kvmonitoraisfrcu7eei' -ApiManagementGatewayUrl 'https://apim-monitorais-frc-u7eei.azure-api.net'

    Runs the script directly with explicitly specified values.
#>
[CmdletBinding()]
param(
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$KeyVaultName = $env:AZURE_KEY_VAULT_NAME,
    [string]$ApiManagementGatewayUrl = $env:AZURE_API_MANAGEMENT_GATEWAY_URL
)

$ErrorActionPreference = 'Stop'

# Validate required parameters
$requiredParameters = @{
    SubscriptionId          = $SubscriptionId
    KeyVaultName            = $KeyVaultName
    ApiManagementGatewayUrl = $ApiManagementGatewayUrl
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

$subscriptionKeySecretName = 'tester-apim-subscription-key'
$moviesApiUrl = "$($ApiManagementGatewayUrl.TrimEnd('/'))/movies"

# Retrieve the subscription key from Key Vault
$subscriptionKey = az keyvault secret show --vault-name $KeyVaultName --name $subscriptionKeySecretName --query value --output tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($subscriptionKey)) {
    throw "Unable to retrieve secret '$subscriptionKeySecretName' from Key Vault '$KeyVaultName'."
}
$headers = "Ocp-Apim-Subscription-Key=$subscriptionKey"

# Retrieve all movies
$moviesJson = az rest --method get --url $moviesApiUrl --headers $headers --skip-authorization-header --output json
if ($LASTEXITCODE -ne 0) {
    throw "Unable to retrieve movies from '$moviesApiUrl'."
}
$movies = @($moviesJson | ConvertFrom-Json)

if ($movies.Count -eq 0) {
    Write-Host "No movies found. Nothing to delete."
    return
}

Write-Verbose "Found $($movies.Count) movie(s) at '$moviesApiUrl':"
$movies | Sort-Object -Property title | ForEach-Object { Write-Verbose "  - $($_.title) ($($_.year)) [$($_.id)]" }

# Confirm the action with the user
$confirmation = Read-Host "Delete all $($movies.Count) movie(s)? Related user ratings will be removed by the integration application. This cannot be undone. [y/N]"
if ($null -eq $confirmation) {
    throw "No confirmation input is available. No movies were deleted. When using 'azd exec', pass '--interactive' to enable confirmation input."
}
if ($confirmation.Trim() -notin @('y', 'yes')) {
    Write-Host 'Deletion cancelled.'
    return
}

# Delete each movie
$failedMovies = @()
foreach ($movie in $movies) {
    Write-Host "Deleting movie '$($movie.title)' [$($movie.id)]"

    az rest --method delete --url "$moviesApiUrl/$($movie.id)" --headers $headers --skip-authorization-header --output none
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Unable to delete movie '$($movie.title)' [$($movie.id)]."
        $failedMovies += $movie
    }
}

if ($failedMovies.Count -gt 0) {
    throw "Unable to delete $($failedMovies.Count) of $($movies.Count) movie(s)."
}

Write-Host "Deleted $($movies.Count) movie(s). It might take a moment before the integration application has removed all related user ratings."
