//=============================================================================
// Azure Workbook
//=============================================================================

//=============================================================================
// Imports
//=============================================================================

import { tagsType } from '../../../99-shared/types.bicep'

//=============================================================================
// Parameters
//=============================================================================

@description('The name of the environment to deploy to')
param environmentName string

@description('Location to use for all resources')
param location string

@description('The tags to associate with the resource')
param tags tagsType

@description('The user-defined name (display name) of the workbook. If an environment is specified, it will be appended to the display name to create a unique display name for the workbook.')
param displayName string

@description('Configuration of this particular workbook. Configuration data is a string containing valid JSON.')
param serializedData string

@description('A dictionary of placeholder values to replace in the serializedData. The keys are the placeholder names, and the values are the replacement values.')
param placeholders { *: string }?

@description('The resource ID of the source resource for the workbook. This can be an Application Insights instance, a Log Analytics workspace, or another supported resource. Defaults to \'azure monitor\' if not specified.')
param sourceId string = 'azure monitor'

@description('Workbook category, as defined by the user at creation time. Default: workbook.')
param category string = 'workbook'

@description('Workbook schema version format, like \'Notebook/1.0\', which should match the workbook in serializedData. Default: Notebook/1.0')
param version string = 'Notebook/1.0'

//=============================================================================
// Variables
//=============================================================================

var workbookDisplayName = environmentName == '' ? displayName : '${displayName} (${environmentName})'
// TODO: Can we fail if the workbookContent still has placeholders after the replacePlaceholders function is called?
var workbookContent = placeholders == null ? serializedData : replacePlaceholders(serializedData, items(placeholders!))

//=============================================================================
// Functions
//=============================================================================

#disable-next-line use-user-defined-types // The used reduce function expects an array, so using array as the type here is correct.
func replacePlaceholders(originalString string, placeholders array) string =>
  reduce(
    placeholders,
    originalString, // this is the first 'current'
    (current, next) => replacePlaceholder(current, next.key, next.value)
  )

func replacePlaceholder(originalString string, placeholder string, value string) string =>
  replace(originalString, '##${placeholder}##', value)

//=============================================================================
// Resources
//=============================================================================

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, displayName, environmentName)
  location: location
  tags: tags
  kind: 'shared' // Only valid value for kind is 'shared'
  properties: {
    displayName: workbookDisplayName
    category: category
    serializedData: workbookContent
    sourceId: sourceId
    version: version
  }
}
