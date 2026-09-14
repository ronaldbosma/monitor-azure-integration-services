namespace IntegrationTests.Clients.MoviesApi.Models;

/// <summary>
/// The properties required to create a movie.
/// </summary>
internal class MovieCreateRequest
{
    public required string Title { get; set; }
    public required string Description { get; set; }
    public required int Year { get; set; }
}
