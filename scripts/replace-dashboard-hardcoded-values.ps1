<#
.SYNOPSIS
    Replaces hardcoded resource ids and names in a dashboard Bicep file with Bicep references.

.DESCRIPTION
    When a dashboard is created or modified in the Azure portal and exported to Bicep, it contains
    hardcoded resource ids and names of the environment it was created in. This script replaces
    those hardcoded values with references to the existing resources declared in the Bicep file.

    The following references are used:
      - appInsights          (Microsoft.Insights/components)
      - serviceBusNamespace  (Microsoft.ServiceBus/namespaces)
      - apiManagement        (Microsoft.ApiManagement/service)
      - logicApp             (Microsoft.Web/sites)
      - functionApp          (Microsoft.Web/sites)
      - resourceGroup()      (function)
      - subscription()       (function)
      - environmentName      (parameter)
      - location             (parameter)

    Resource ids are replaced first, because they contain the resource names. Then the resource names are
    replaced, followed by the environment name and location, because the resource names contain these.
    The 'INSERT LOCATION' placeholder of an exported dashboard is also replaced by the location parameter.
    For each value, the following replacements are made (case-insensitive):
      1. Entire property values are replaced by a reference.
         E.g. 'sbns-monitorais-sdc-45gou' becomes serviceBusNamespace.name
      2. Values inside longer strings are replaced by an interpolated reference.
         E.g. 'Messages for sbns-monitorais-sdc-45gou' becomes 'Messages for ${serviceBusNamespace.name}'

    Before these replacements, the following dashboard specific replacements are made:
      - The resource symbol Environment_Overview_<environment name> becomes environmentOverviewDashboard
      - name: 'Environment Overview - <environment name>' becomes name: environmentOverviewDashboardName
      - tags: { 'hidden-title': ... } becomes tags: union(tags, { 'hidden-title': ... })
      - Microsoft.Portal/dashboards@2022-12-01-preview becomes Microsoft.Portal/dashboards@2025-04-01-preview

    Make sure the Bicep file declares the referenced resources (e.g. with the 'existing' keyword),
    the environmentName, location and tags parameters and the environmentOverviewDashboardName variable.

.PARAMETER FilePath
    Path to the Bicep file in which the values should be replaced.
    Defaults to (Join-Path $PSScriptRoot '../infra/03-monitoring/modules/dashboards.bicep').

.PARAMETER EnvironmentName
    The name of the environment. Defaults to the AZURE_ENV_NAME environment variable.

.PARAMETER Location
    The location of the resources. Defaults to the AZURE_LOCATION environment variable.

.PARAMETER SubscriptionId
    The id of the Azure subscription. Defaults to the AZURE_SUBSCRIPTION_ID environment variable.

.PARAMETER ResourceGroupName
    The name of the resource group. Defaults to the AZURE_RESOURCE_GROUP environment variable.

.PARAMETER AppInsightsName
    The name of the Application Insights instance. Defaults to the AZURE_APPLICATION_INSIGHTS_NAME environment variable.

.PARAMETER ServiceBusNamespaceName
    The name of the Service Bus namespace. Defaults to the AZURE_SERVICE_BUS_NAMESPACE_NAME environment variable.

.PARAMETER ApiManagementName
    The name of the API Management instance. Defaults to the AZURE_API_MANAGEMENT_NAME environment variable.

.PARAMETER LogicAppName
    The name of the Logic App. Defaults to the AZURE_LOGIC_APP_NAME environment variable.

.PARAMETER FunctionAppName
    The name of the Function App. Defaults to the AZURE_FUNCTION_APP_NAME environment variable.

.EXAMPLE
    azd exec ./scripts/replace-dashboard-hardcoded-values.ps1

    Runs the script with the environment variables of the current azd environment.

.EXAMPLE
    azd exec ./scripts/replace-dashboard-hardcoded-values.ps1 -- -FilePath ./my-dashboard.bicep

    Runs the script with the environment variables of the current azd environment on a specific file.

.EXAMPLE
    ./scripts/replace-dashboard-hardcoded-values.ps1 -EnvironmentName 'monitorais' -Location 'swedencentral' `
        -SubscriptionId '<subscription-id>' -ResourceGroupName 'rg-monitorais-sdc-45gou' `
        -AppInsightsName 'appi-monitorais-sdc-45gou' -ServiceBusNamespaceName 'sbns-monitorais-sdc-45gou' `
        -ApiManagementName 'apim-monitorais-sdc-45gou' -LogicAppName 'logic-monitorais-sdc-45gou' `
        -FunctionAppName 'func-monitorais-sdc-45gou'

    Runs the script directly with explicitly specified values.
#>
[CmdletBinding()]
param(
    [string]$FilePath = (Join-Path $PSScriptRoot '../infra/03-monitoring/modules/dashboards.bicep'),
    [string]$EnvironmentName = $env:AZURE_ENV_NAME,
    [string]$Location = $env:AZURE_LOCATION,
    [string]$SubscriptionId = $env:AZURE_SUBSCRIPTION_ID,
    [string]$ResourceGroupName = $env:AZURE_RESOURCE_GROUP,
    [string]$AppInsightsName = $env:AZURE_APPLICATION_INSIGHTS_NAME,
    [string]$ServiceBusNamespaceName = $env:AZURE_SERVICE_BUS_NAMESPACE_NAME,
    [string]$ApiManagementName = $env:AZURE_API_MANAGEMENT_NAME,
    [string]$LogicAppName = $env:AZURE_LOGIC_APP_NAME,
    [string]$FunctionAppName = $env:AZURE_FUNCTION_APP_NAME
)

$ErrorActionPreference = 'Stop'

$requiredParameters = @{
    EnvironmentName         = $EnvironmentName
    Location                = $Location
    SubscriptionId          = $SubscriptionId
    ResourceGroupName       = $ResourceGroupName
    AppInsightsName         = $AppInsightsName
    ServiceBusNamespaceName = $ServiceBusNamespaceName
    ApiManagementName       = $ApiManagementName
    LogicAppName            = $LogicAppName
    FunctionAppName         = $FunctionAppName
}
$missingParameters = $requiredParameters.GetEnumerator() | Where-Object { [string]::IsNullOrWhiteSpace($_.Value) } | ForEach-Object { $_.Key }
if ($missingParameters) {
    throw "The following parameters are not specified and have no environment variable value: $($missingParameters -join ', '). Specify them explicitly or run the script using 'azd exec'."
}

$resolvedFilePath = (Resolve-Path -Path $FilePath).Path
$resourceGroupId = "/subscriptions/$SubscriptionId/resourceGroups/$ResourceGroupName"

# Ids must be replaced before resource names, and resource names before the environment name and location, because they contain each other
$replacements = [ordered]@{
    "$resourceGroupId/providers/Microsoft.Insights/components/$AppInsightsName"         = 'appInsights.id'
    "$resourceGroupId/providers/Microsoft.ServiceBus/namespaces/$ServiceBusNamespaceName" = 'serviceBusNamespace.id'
    "$resourceGroupId/providers/Microsoft.Web/sites/$LogicAppName"                      = 'logicApp.id'
    "$resourceGroupId/providers/Microsoft.Web/sites/$FunctionAppName"                   = 'functionApp.id'
    $AppInsightsName                                                                     = 'appInsights.name'
    $ServiceBusNamespaceName                                                             = 'serviceBusNamespace.name'
    $ApiManagementName                                                                   = 'apiManagement.name'
    $LogicAppName                                                                        = 'logicApp.name'
    $FunctionAppName                                                                     = 'functionApp.name'
    $ResourceGroupName                                                                   = 'resourceGroup().name'
    $SubscriptionId                                                                      = 'subscription().subscriptionId'
    $EnvironmentName                                                                     = 'environmentName'
    $Location                                                                            = 'location'
    'INSERT LOCATION'                                                                    = 'location'
}

$content = [System.IO.File]::ReadAllText($resolvedFilePath)
$regexOptions = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase

# Must be replaced before the generic replacements, because these contain the environment name
$escapedEnvironmentName = [regex]::Escape($EnvironmentName)
$dashboardReplacements = [ordered]@{
    "Environment_Overview_$([regex]::Escape(($EnvironmentName -replace '-', '_')))"                  = 'environmentOverviewDashboard'
    "name: 'Environment Overview - $escapedEnvironmentName'"                                       = 'name: environmentOverviewDashboardName'
    "tags: \{(\s*'hidden-title': 'Environment Overview - $escapedEnvironmentName'\s*)\}"            = 'tags: union(tags, {$1})'
    'Microsoft\.Portal/dashboards@2022-12-01-preview'                                              = 'Microsoft.Portal/dashboards@2025-04-01-preview'
}

foreach ($replacement in $dashboardReplacements.GetEnumerator()) {
    $pattern = $replacement.Key
    $newValue = $replacement.Value
    $count = [regex]::Matches($content, $pattern, $regexOptions).Count
    $content = [regex]::Replace($content, $pattern, $newValue, $regexOptions)

    Write-Host "$pattern"
    Write-Host "  => $newValue ($count occurrences)"
}

foreach ($replacement in $replacements.GetEnumerator()) {
    $escapedValue = [regex]::Escape($replacement.Key)
    $reference = $replacement.Value
    $interpolatedReference = '${' + $reference + '}'

    # Entire property value, e.g. 'sbns-monitorais-sdc-45gou' => serviceBusNamespace.name
    $propertyValuePattern = "'$escapedValue'"
    $propertyValueCount = [regex]::Matches($content, $propertyValuePattern, $regexOptions).Count
    $content = [regex]::Replace($content, $propertyValuePattern, { param($m) $reference }, $regexOptions)

    # Value inside a longer string, e.g. sbns-monitorais-sdc-45gou => ${serviceBusNamespace.name}
    $inlineCount = [regex]::Matches($content, $escapedValue, $regexOptions).Count
    $content = [regex]::Replace($content, $escapedValue, { param($m) $interpolatedReference }, $regexOptions)

    Write-Host "$($replacement.Key)"
    Write-Host "  => $reference ($propertyValueCount property values, $inlineCount inside strings)"
}

[System.IO.File]::WriteAllText($resolvedFilePath, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "Updated '$resolvedFilePath'" -ForegroundColor Green
