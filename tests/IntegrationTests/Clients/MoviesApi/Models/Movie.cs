namespace IntegrationTests.Clients.MoviesApi.Models;

/// <summary>
/// Full details of a movie.
/// </summary>
internal class Movie
{
    public required Guid Id { get; set; }
    public required string Title { get; set; }
    public required string Description { get; set; }
    public required int Year { get; set; }
    public double? Rating { get; set; }
}
