namespace IntegrationTests.Clients.UserRatingsApi.Models;

/// <summary>
/// An error response returned by the User Ratings API.
/// </summary>
internal class ErrorResponse
{
    public required int StatusCode { get; set; }
    public required string Message { get; set; }
}
