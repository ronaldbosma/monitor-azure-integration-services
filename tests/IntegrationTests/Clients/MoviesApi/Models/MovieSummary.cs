namespace IntegrationTests.Clients.MoviesApi.Models;

/// <summary>
/// Summary information about a movie.
/// </summary>
internal class MovieSummary
{
    public required Guid Id { get; set; }
    public required string Title { get; set; }
    public required int Year { get; set; }

    public static MovieSummary FromMovie(Movie movie)
    {
        return new MovieSummary
        {
            Id = movie.Id,
            Title = movie.Title,
            Year = movie.Year
        };
    }
}
