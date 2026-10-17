<#
.SYNOPSIS
    Creates 25 fictional movies and adds three user ratings to 20 of them.

.DESCRIPTION
    Creates movies with realistic fictional titles, descriptions and release years using
    the Movies API, then adds three ratings per movie for the first 20 movies using the
    User Ratings API. The remaining five movies are left unrated.
    HTTP requests are performed using 'az rest'.

    The API Management subscription key is read from the 'tester-apim-subscription-key'
    secret in Key Vault. The logged in user needs permission to read secrets from the
    Key Vault (e.g. the Key Vault Secrets User role).

    Stops on the first failed request. Previously created movies and ratings are not
    rolled back. Movie titles must be unique, so running the script again without
    deleting the demo movies first will fail.

    Movie ratings are recalculated asynchronously by the integration application.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER KeyVaultName
    The name of the Key Vault. Defaults to the AZURE_KEY_VAULT_NAME environment variable.

.PARAMETER ApiManagementGatewayUrl
    The gateway URL of the API Management service. Defaults to the AZURE_API_MANAGEMENT_GATEWAY_URL environment variable.

.EXAMPLE
    azd exec ./scripts/create-demo-movies.ps1

    Creates 25 movies and 40 user ratings using the current azd environment.

.EXAMPLE
    ./scripts/create-demo-movies.ps1 -SubscriptionId '<subscription-id>' `
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

# Retrieve the subscription key from Key Vault
$subscriptionKeySecretName = 'tester-apim-subscription-key'
$subscriptionKey = az keyvault secret show --vault-name $KeyVaultName --name $subscriptionKeySecretName --query value --output tsv
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($subscriptionKey)) {
    throw "Unable to retrieve secret '$subscriptionKeySecretName' from Key Vault '$KeyVaultName'."
}

$headers = @("Ocp-Apim-Subscription-Key=$subscriptionKey", 'Content-Type=application/json')
$gatewayUrl = $ApiManagementGatewayUrl.TrimEnd('/')
$moviesApiUrl = "$gatewayUrl/movies"
$userRatingsApiUrl = "$gatewayUrl/user-ratings"

# AI-generated demo movies
$movies = @(
    @{
        title = 'The Last Light in Bellweather'
        description = 'A retired lighthouse keeper and a runaway teenager restore a coastal beacon as a winter storm threatens the fishing fleet that abandoned their town.'
        year = 2018
    }
    @{
        title = 'Midnight on Platform Nine'
        description = 'An overnight railway dispatcher hears a missing passenger calling from a station that closed thirty years ago and boards the last train to investigate.'
        year = 2022
    }
    @{
        title = 'A Summer for Strangers'
        description = 'Three travelers stranded in a sleepy Italian village agree to run its failing guesthouse for a month, finding unexpected friendships behind the reception desk.'
        year = 2016
    }
    @{
        title = 'The Glass Meridian'
        description = 'A cartographer aboard a deep-space survey ship discovers that an unexplored planet appears on a map drawn by her father before she was born.'
        year = 2024
    }
    @{
        title = 'Small Hours in December'
        description = 'A night-shift nurse and a widowed taxi driver share a series of chance encounters while trying to bring their estranged families home for the holidays.'
        year = 2019
    }
    @{
        title = 'The Orchard Beyond the River'
        description = 'After inheriting a neglected apple farm, a city accountant uncovers a family dispute that could cost an entire valley its next harvest.'
        year = 2014
    }
    @{
        title = 'Dead Reckoning at Dawn'
        description = 'A salvage captain accepts one final job in the North Atlantic, only to discover that her crew has been hired to recover evidence rather than treasure.'
        year = 2021
    }
    @{
        title = 'Paper Moons over Marlow'
        description = 'An anxious schoolteacher recruits her eccentric neighbors to save a community theater with a musical none of them knows how to stage.'
        year = 2017
    }
    @{
        title = 'The Quiet Frequency'
        description = 'A sound engineer restoring old radio broadcasts finds coded warnings about accidents that have yet to happen and races to identify the voice behind them.'
        year = 2023
    }
    @{
        title = 'Where the Cinders Fall'
        description = 'Two estranged brothers return to their mining hometown after a factory fire and must choose between protecting their family and exposing its oldest secret.'
        year = 2011
    }
    @{
        title = 'Borrowed Shoes'
        description = 'A struggling wedding photographer accidentally swaps bags with a professional dancer and spends a chaotic weekend pretending to be someone with better prospects.'
        year = 2020
    }
    @{
        title = 'The Ninth Winter'
        description = 'In an isolated mountain settlement, a young doctor challenges a generations-old evacuation ritual when the first snowfall brings an unexpected visitor.'
        year = 2015
    }
    @{
        title = 'Letters from Alder Street'
        description = 'A postal worker nearing retirement delivers a sack of forgotten letters and watches their long-delayed promises transform the neighborhood where she grew up.'
        year = 2008
    }
    @{
        title = 'Velocity of Silence'
        description = 'A former motorcycle champion coaches a gifted deaf teenager, forcing both riders to confront the risks they take on and off the track.'
        year = 2025
    }
    @{
        title = 'The Clockmaker of Saint Vale'
        description = 'An apprentice repairing the clocks of a hillside city discovers that each stopped mechanism holds a memory its owner has chosen to forget.'
        year = 2013
    }
    @{
        title = 'One More Table'
        description = 'On the final night of a family restaurant, a headstrong chef and her father attempt to serve a surprise wedding party without discussing why they are closing.'
        year = 2022
    }
    @{
        title = 'Beneath the Copper Sky'
        description = 'A geologist and a local pilot search an abandoned desert observatory for a missing researcher as an approaching dust storm cuts off their escape.'
        year = 2006
    }
    @{
        title = 'The Unfinished Waltz'
        description = 'A concert pianist recovering from an injury returns to her childhood town, where an amateur orchestra asks her to finish her late teacher''s final composition.'
        year = 2010
    }
    @{
        title = 'Exit Through the Harbor'
        description = 'A customs inspector following a routine shipping discrepancy uncovers a smuggling network and learns that her most trusted informant arranged the discovery.'
        year = 2018
    }
    @{
        title = 'A Map of All Our Mistakes'
        description = 'Two former best friends retrace a disastrous road trip to return a borrowed car, discovering that their memories of the journey have little in common.'
        year = 2024
    }
    @{
        title = 'The Blue Hour Express'
        description = 'An aging jazz singer takes a cross-country train to her farewell concert and forms an unlikely band with the strangers sharing her carriage.'
        year = 2003
    }
    @{
        title = 'Garden of Mechanical Birds'
        description = 'A young inventor builds a flock of tiny machines to help her grandfather tend his rooftop garden, accidentally attracting the attention of a lonely city.'
        year = 2021
    }
    @{
        title = 'Before the Lake Freezes'
        description = 'A wildlife ranger has one week to find a missing field notebook that could protect a remote wetland from a development supported by her own brother.'
        year = 2016
    }
    @{
        title = 'Room for the Rain'
        description = 'When a leaking roof forces a meticulous landlord to move in with her tenants, their improvised repairs unravel the carefully ordered life she has built.'
        year = 2012
    }
    @{
        title = 'The Far Side of Morning'
        description = 'The crew of a lunar research station receives a farewell message from Earth and must decide whether to attempt a dangerous return or investigate its origin.'
        year = 2025
    }
)

$userIds = @(
    [guid]::NewGuid().ToString()
    [guid]::NewGuid().ToString()
    [guid]::NewGuid().ToString()
)
$createdMovieCount = 0
$createdRatingCount = 0

# File-based bodies avoid native command JSON quoting differences across PowerShell versions.
$requestBodyPath = [System.IO.Path]::GetTempFileName()
try {
    for ($movieIndex = 0; $movieIndex -lt $movies.Count; $movieIndex++) {
        $movie = $movies[$movieIndex]
        $movie.id = [guid]::NewGuid().ToString()
        $movieBody = $movie | ConvertTo-Json -Compress
        [System.IO.File]::WriteAllText($requestBodyPath, $movieBody)

        Write-Host "Creating movie '$($movie.title)' ($($movie.year)) [$($movie.id)]"
        az rest --method post --url $moviesApiUrl --headers $headers --body "@$requestBodyPath" --skip-authorization-header --output none
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to create movie '$($movie.title)'. Created $createdMovieCount movie(s) and $createdRatingCount user rating(s) before this failure. Existing data has not been rolled back."
        }
        $createdMovieCount++

        if ($movieIndex -lt 20) {
            foreach ($userId in $userIds) {
                $rating = Get-Random -Minimum 1 -Maximum 11
                $ratingBody = @{
                    movieId = $movie.id
                    userId = $userId
                    rating = $rating
                } | ConvertTo-Json -Compress
                [System.IO.File]::WriteAllText($requestBodyPath, $ratingBody)

                Write-Verbose "Adding rating $rating for movie '$($movie.title)' by user '$userId'."
                az rest --method put --url $userRatingsApiUrl --headers $headers --body "@$requestBodyPath" --skip-authorization-header --output none
                if ($LASTEXITCODE -ne 0) {
                    throw "Unable to add rating for movie '$($movie.title)' by user '$userId'. Created $createdMovieCount movie(s) and $createdRatingCount user rating(s) before this failure. Existing data has not been rolled back."
                }
                $createdRatingCount++
            }
        }
    }
}
finally {
    Remove-Item -LiteralPath $requestBodyPath -Force
}

Write-Host "Created $createdMovieCount movies and $createdRatingCount user ratings. Five movies were left unrated. It might take a moment before the integration application has recalculated the movie ratings."
