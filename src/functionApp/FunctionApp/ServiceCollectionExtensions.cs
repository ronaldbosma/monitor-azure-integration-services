using Azure.Core;
using Azure.Data.Tables;
using Azure.Identity;
using Azure.Monitor.OpenTelemetry.Exporter;

using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

using OpenTelemetry.Trace;

namespace FunctionApp;

internal static class ServiceCollectionExtensions
{
    public static IServiceCollection ConfigureOpenTelemetry(this IServiceCollection services)
    {
        services.AddOpenTelemetry()
            .WithTracing(tracing => tracing
                // Enables HttpClient instrumentation.
                .AddHttpClientInstrumentation())

            .UseAzureMonitorExporter(options =>
            {
                // Set the Azure Monitor credential to the DefaultAzureCredential.
                // This credential will use the Azure identity of the current user or
                // the service principal that the application is running as to authenticate
                // to Azure Monitor.
                // Use a more specific credential in production scenarios. For best practices, see
                // https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication/best-practices?tabs=aspdotnet
                options.Credential = new DefaultAzureCredential();
            })

            .UseFunctionsWorkerDefaults();

        return services;
    }

    public static IServiceCollection RegisterDependencies(this IServiceCollection services, ConfigurationManager configuration)
    {
        services.AddOptionsWithValidateOnStart<ApiManagementOptions>()
                .BindConfiguration(ApiManagementOptions.SectionKey)
                .ValidateDataAnnotations();

        services.AddHttpClient("apim", (sp, client) =>
                {
                    var options = sp.GetRequiredService<IOptions<ApiManagementOptions>>().Value;
                    client.BaseAddress = new Uri(options.GatewayUrl);
                    client.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", options.SubscriptionKey);
                });

        var tableServiceUri = configuration["StorageAccountConnection:tableServiceUri"]
            ?? throw new InvalidOperationException("Configuration setting 'StorageAccountConnection:tableServiceUri' is missing.");
        services.AddSingleton(new TableServiceClient(new Uri(tableServiceUri), new DefaultAzureCredential()));

        return services;
    }
}
