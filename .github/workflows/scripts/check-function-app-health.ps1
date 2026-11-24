<#
.SYNOPSIS
    Checks the health of the Azure Function App.

.DESCRIPTION
    Requests /api/health and verifies that the Function App returns HTTP 200.
    Logs the status and response body for every attempt, or the error if the request fails.
    Retries unsuccessful checks and throws if the endpoint does not become healthy.

.PARAMETER FunctionAppEndpoint
    The base URL of the Function App. Defaults to the AZURE_FUNCTION_APP_ENDPOINT environment variable.

.PARAMETER MaxRetries
    The maximum number of retries after the initial check. Defaults to 30.

.PARAMETER RetryIntervalSeconds
    The delay in seconds between unsuccessful checks. Defaults to 10.

.EXAMPLE
    azd exec ./check-function-app-health.ps1

    Checks the Function App health using the environment variables of the current azd environment.

.EXAMPLE
    ./check-function-app-health.ps1 -FunctionAppEndpoint 'https://func-monitorais-frc-u7eei.azurewebsites.net' `
        -MaxRetries 5 -RetryIntervalSeconds 2

    Runs the script directly with explicitly specified values.
#>
#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$FunctionAppEndpoint = $env:AZURE_FUNCTION_APP_ENDPOINT,
    [ValidateRange(0, 2147483646)]
    [int]$MaxRetries = 30,
    [ValidateRange(0, 2147483647)]
    [int]$RetryIntervalSeconds = 10
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($FunctionAppEndpoint)) {
    throw "FunctionAppEndpoint is not specified and has no environment variable value. Specify it explicitly or run the script using 'azd exec'."
}

$endpointUri = $null
if (-not [Uri]::TryCreate($FunctionAppEndpoint, [UriKind]::Absolute, [ref]$endpointUri) -or
    $endpointUri.Scheme -notin @('http', 'https')) {
    throw 'FunctionAppEndpoint must be an absolute HTTP or HTTPS URL.'
}

$healthUrl = "$($FunctionAppEndpoint.TrimEnd('/'))/api/health"
$maxAttempts = $MaxRetries + 1

for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    Write-Host "Checking Function App health at '$healthUrl' (attempt $attempt/$maxAttempts)."

    try {
        $response = Invoke-WebRequest -Uri $healthUrl -SkipHttpErrorCheck
    }
    catch [System.Net.Http.HttpRequestException], [System.Net.WebException], [System.Threading.Tasks.TaskCanceledException] {
        Write-Host "Result: Request failed. Output: $($_.Exception.Message)"
        $response = $null
    }

    if ($null -ne $response) {
        Write-Host "Result: HTTP $([int]$response.StatusCode). Output: $($response.Content)"
        if ($response.StatusCode -eq 200) {
            Write-Host 'Function App is healthy.'
            return
        }
    }

    if ($attempt -lt $maxAttempts) {
        Start-Sleep -Seconds $RetryIntervalSeconds
    }
}

throw "Function App health check failed after $maxAttempts attempts. Expected HTTP 200 from '$healthUrl'."
