using Azure.Messaging.ServiceBus;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace FunctionApp.HealthChecks;

/// <summary>
/// Represents a health check for the deleted movies subscription in Azure Service Bus.
/// </summary>
internal class DeletedMoviesSubscriptionHealthCheck : IHealthCheck
{
    private readonly ServiceBusClient _serviceBusClient;

    public DeletedMoviesSubscriptionHealthCheck(ServiceBusClient serviceBusClient)
    {
        _serviceBusClient = serviceBusClient;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            await using var receiver = _serviceBusClient.CreateReceiver(
                Constants.DeletedMoviesTopicName,
                Constants.DeletedMoviesSubscriptionName);

            await receiver.PeekMessageAsync(fromSequenceNumber: null, cancellationToken: cancellationToken);

            return HealthCheckResult.Healthy();
        }
        catch (Exception ex)
        {
            // Users don't experience any issues if the subscription is not accessible, so we return a degraded health check result instead of unhealthy.
            return HealthCheckResult.Degraded(
                description: $"Unable to access Service Bus subscription",
                exception: ex,
                data: new Dictionary<string, object>
                {
                    { "TopicName", Constants.DeletedMoviesTopicName },
                    { "SubscriptionName", Constants.DeletedMoviesSubscriptionName }
                }
            );
        }
    }
}
