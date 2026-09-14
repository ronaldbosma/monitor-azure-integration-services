using IntegrationTests.Clients.MoviesApi.Models;

namespace IntegrationTests.Helpers;

internal class MovieBuilder
{
    public Movie Build()
    {
        return new Movie
        {
            Id = Guid.NewGuid(),
            Title = $"Test Movie {Guid.NewGuid()}",
            Description = "This is a test movie.",
            Year = 2023,
            Rating = 8.5
        };
    }

    public List<Movie> BuildMany(int count = 3)
    {
        var movies = new List<Movie>();
        for (int i = 0; i < count; i++)
        {
            movies.Add(Build());
        }
        return movies;
    }
}
