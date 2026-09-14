namespace IntegrationTests.Clients.MoviesApi.Models;

/// <summary>
/// The properties that can be updated on a movie. All properties are optional, only the provided properties are updated.
/// </summary>
internal class MovieUpdateRequest
{
    public string? Title { get; set; }
    public string? Description { get; set; }
    public int? Year { get; set; }
    public double? Rating { get; set; }
}
