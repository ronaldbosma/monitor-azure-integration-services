using Azure.Data.Tables;

using FunctionApp.Models;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace FunctionApp.Api;

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
    public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get")] HttpRequest req)
    {
        _logger.LogInformation("GetUserRatingsFunction processed a request.");

        var movieIdStr = req.Query["movie-id"].ToString();
        if (string.IsNullOrWhiteSpace(movieIdStr) || !Guid.TryParse(movieIdStr, out var movieId))
        {
            return new BadRequestObjectResult("Please provide a valid movie-id (GUID) in the query string, e.g. ?movie-id={guid}");
        }

        var tableClient = _tableServiceClient.GetTableClient("userratings");

        try
        {
            // Query all entities where PartitionKey == movieId
            string filter = $"PartitionKey eq '{movieIdStr}'";
            var query = tableClient.Query<UserRatingEntity>(filter: filter);

            var results = query.Select(e => new UserRating
            {
                MovieId = movieId,
                UserId = Guid.Parse(e.RowKey),
                Rating = e.Rating
            }).ToList();

            return new OkObjectResult(results);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error querying user ratings for movie {MovieId}", movieId);
            return new ObjectResult("Failed to retrieve user ratings") { StatusCode = 500 };
        }
    }
}
