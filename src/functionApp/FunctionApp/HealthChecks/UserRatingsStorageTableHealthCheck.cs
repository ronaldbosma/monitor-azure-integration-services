using Azure.Data.Tables;

using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace FunctionApp.HealthChecks;

/// <summary>
/// Represents a health check for the user ratings storage table in Azure Table Storage.
/// </summary>
internal class UserRatingsStorageTableHealthCheck : IHealthCheck
{
    private readonly TableServiceClient _tableServiceClient;

    public UserRatingsStorageTableHealthCheck(TableServiceClient tableServiceClient)
    {
        _tableServiceClient = tableServiceClient;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            var tableClient = _tableServiceClient.GetTableClient(Constants.UserRatingsTableName);
            await tableClient
                .QueryAsync<TableEntity>(maxPerPage: 1, cancellationToken: cancellationToken)
                .GetAsyncEnumerator(cancellationToken)
                .MoveNextAsync();

            return HealthCheckResult.Healthy();

        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy(
                description: $"Unable to access storage table {Constants.UserRatingsTableName}",
                exception: ex
            );
        }
    }
}
