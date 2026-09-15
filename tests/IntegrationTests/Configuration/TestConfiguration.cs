using Microsoft.Extensions.Configuration;

namespace IntegrationTests.Configuration;

/// <summary>
/// Contains configuration settings for the integration tests.
/// </summary>
internal class TestConfiguration
{
    private static readonly Lazy<TestConfiguration> Instance = new(() =>
    {
        AzdDotEnv.Load(optional: true); // Loads Azure Developer CLI environment variables; optional since .env file might be missing in CI/CD pipelines

        var configuration = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        return new TestConfiguration
        {
            AzureApiManagementGatewayUrl = configuration.GetRequiredUri("AZURE_API_MANAGEMENT_GATEWAY_URL"),
            AzureKeyVaultUri = configuration.GetRequiredUri("AZURE_KEY_VAULT_URI"),
            AzureTenantId = configuration.GetRequiredString("AZURE_TENANT_ID"),
            AzureSubscriptionId = configuration.GetRequiredString("AZURE_SUBSCRIPTION_ID"),
            AzureResourceGroup = configuration.GetRequiredString("AZURE_RESOURCE_GROUP"),
            AzureLogicAppName = configuration.GetRequiredString("AZURE_LOGIC_APP_NAME")
        };
    });

    public required Uri AzureApiManagementGatewayUrl { get; init; }
    public required Uri AzureKeyVaultUri { get; init; }

    public required string AzureTenantId { get; init; }
    public required string AzureSubscriptionId { get; init; }
    public required string AzureResourceGroup { get; init; }
    public required string AzureLogicAppName { get; init; }

    public static TestConfiguration Load() => Instance.Value;
}