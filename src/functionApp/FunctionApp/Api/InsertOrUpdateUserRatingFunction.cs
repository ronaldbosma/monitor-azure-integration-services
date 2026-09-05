using System.ComponentModel.DataAnnotations;
using System.Diagnostics.CodeAnalysis;
using System.Text.Json;

using Azure.Data.Tables;

using FunctionApp.Models;

using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace FunctionApp.Api;

public class InsertOrUpdateUserRatingFunction
{
    private readonly TableServiceClient _tableServiceClient;
    private readonly ILogger<InsertOrUpdateUserRatingFunction> _logger;

    public InsertOrUpdateUserRatingFunction(TableServiceClient tableServiceClient, ILogger<InsertOrUpdateUserRatingFunction> logger)
    {
        _tableServiceClient = tableServiceClient;
        _logger = logger;
    }

    [Function("InsertOrUpdateUserRatingFunction")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "post", "put")] HttpRequest req)
    {
        _logger.LogInformation("InsertOrUpdateUserRatingFunction processed a request.");

        var userRating = await ParseRequestAsync(req);
        if (userRating == null)
        {
            return new BadRequestObjectResult("Request body must be valid JSON and contain movieId, userId and rating.");
        }

        if (!IsValidUserRating(userRating, out var validationResult))
        {
            return validationResult;
        }

        return await InsertOrUpdateUserRatingAsync(userRating);
    }

    private async Task<UserRating?> ParseRequestAsync(HttpRequest req)
    {
        try
        {
            return await req.ReadFromJsonAsync<UserRating>();
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to deserialize request body");
            return null;
        }
    }

    private static bool IsValidUserRating(UserRating userRating, [NotNullWhen(false)] out IActionResult? result)
    {
        // Validate data annotations
        var context = new ValidationContext(userRating);
        var results = new List<ValidationResult>();
        if (!Validator.TryValidateObject(userRating, context, results, true))
        {
            result = new BadRequestObjectResult(results.Select(r => r.ErrorMessage));
            return false;
        }

        // Additional validation for GUIDs: ensure they are not Guid.Empty
        if (userRating.MovieId == Guid.Empty || userRating.UserId == Guid.Empty)
        {
            result = new BadRequestObjectResult("movieId and userId must be valid non-empty GUIDs.");
            return false;
        }

        result = null;
        return true;
    }

    private async Task<IActionResult> InsertOrUpdateUserRatingAsync(UserRating userRating)
    {
        try
        {
            var tableClient = _tableServiceClient.GetTableClient("userratings");
            await tableClient.CreateIfNotExistsAsync();

            var entity = new UserRatingEntity
            {
                PartitionKey = userRating.MovieId.ToString(),
                RowKey = userRating.UserId.ToString(),
                Rating = userRating.Rating
            };

            tableClient.UpsertEntity(entity, TableUpdateMode.Replace);

            return new OkObjectResult(new { message = "Rating inserted/updated successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error inserting/updating user rating for movie {MovieId} user {UserId}", userRating.MovieId, userRating.UserId);
            return new ObjectResult("Failed to insert or update user rating") { StatusCode = 500 };
        }
    }
}
