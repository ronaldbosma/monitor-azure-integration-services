using Azure.Data.Tables;

using FunctionApp.Models;

using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace FunctionApp.EventHandlers;

public class MovieDeletedEventHandlerFunction
{
    private readonly TableServiceClient _tableServiceClient;
    private readonly ILogger<MovieDeletedEventHandlerFunction> _logger;

    public MovieDeletedEventHandlerFunction(TableServiceClient tableServiceClient, ILogger<MovieDeletedEventHandlerFunction> logger)
    {
        _tableServiceClient = tableServiceClient;
        _logger = logger;
    }

    [Function("MovieDeletedEventHandlerFunction")]
    public async Task Run(
        [ServiceBusTrigger("deleted-movies", "function-app", Connection = "ServiceBusConnection")]
        MovieDeletedEvent deletedMovie)
    {
        var tableClient = _tableServiceClient.GetTableClient("userratings");

        try
        {
            await tableClient.CreateIfNotExistsAsync();

            string partitionKey = deletedMovie.Id.ToString();
            string filter = $"PartitionKey eq '{partitionKey}'";

            int deleted = 0;
            await foreach (var entity in tableClient.QueryAsync<UserRatingEntity>(filter: filter))
            {
                await tableClient.DeleteEntityAsync(entity.PartitionKey, entity.RowKey);
                deleted++;
            }

            _logger.LogInformation("Deleted {Count} user ratings for movie {MovieId}", deleted, deletedMovie.Id);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting user ratings for movie {MovieId}", deletedMovie.Id);
        }
    }
}
