using Azure.Data.Tables;

using FunctionApp.Models;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace FunctionApp.Api;

/// <summary>
/// Retrieves user ratings for a specific movie based on the provided movie ID.
/// </summary>
public class GetUserRatingsFunction
{
    private readonly TableServiceClient _tableServiceClient;
    private readonly ILogger<GetUserRatingsFunction> _logger;

    public GetUserRatingsFunction(TableServiceClient tableServiceClient, ILogger<GetUserRatingsFunction> logger)
    {
        _tableServiceClient = tableServiceClient;
        _logger = logger;
    }

    [Function("GetUserRatingsFunction")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "get", Route = "user-ratings")] HttpRequest req)
    {
        _logger.LogInformation("GetUserRatingsFunction processed a request.");

        var movieIdStr = req.Query["movie-id"].ToString();
        if (string.IsNullOrWhiteSpace(movieIdStr) || !Guid.TryParse(movieIdStr, out var movieId))
        {
            return new BadRequestObjectResult("Please provide a valid movie-id (GUID) in the query string, e.g. ?movie-id={guid}");
        }

        var tableClient = _tableServiceClient.GetTableClient(Constants.UserRatingsTableName);

        try
        {
            // Query all entities where PartitionKey == movieId
            string filter = $"PartitionKey eq '{movieId}'";
            var query = tableClient.QueryAsync<UserRatingEntity>(filter: filter, cancellationToken: req.HttpContext.RequestAborted);

            var results = new List<UserRating>();
            await foreach (var entity in query)
            {
                results.Add(new UserRating
                {
                    MovieId = movieId,
                    UserId = Guid.Parse(entity.RowKey),
                    Rating = entity.Rating
                });
            }

            return new OkObjectResult(results);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error querying user ratings for movie {MovieId}", movieId);
            return new ObjectResult("Failed to retrieve user ratings") { StatusCode = 500 };
        }
    }
}
