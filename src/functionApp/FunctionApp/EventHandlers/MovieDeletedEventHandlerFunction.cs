using Azure.Data.Tables;

using FunctionApp.Models;

using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace FunctionApp.EventHandlers;

/// <summary>
/// Handles the deletion of a movie by removing all associated user ratings from the table storage.
/// </summary>
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
            string filter = $"PartitionKey eq '{deletedMovie.Id}'";
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
            throw;
        }
    }
}
