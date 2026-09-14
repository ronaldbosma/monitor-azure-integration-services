namespace IntegrationTests.Clients.MoviesApi.Models;

/// <summary>
/// An error response returned by the Movies API.
/// </summary>
internal class ErrorResponse
{
    public required int StatusCode { get; set; }
    public required string Message { get; set; }
}
