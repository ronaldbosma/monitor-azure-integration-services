namespace IntegrationTests.Clients.MoviesApi.Models;

/// <summary>
/// The properties required to create a movie.
/// </summary>
internal class MovieCreateRequest
{
    public required Guid Id { get; set; }
    public required string Title { get; set; }
    public required string Description { get; set; }
    public required int Year { get; set; }

    public static MovieCreateRequest FromMovie(Movie movie)
    {
        return new MovieCreateRequest
        {
            Id = movie.Id,
            Title = movie.Title,
            Description = movie.Description,
            Year = movie.Year
        };
    }
}
