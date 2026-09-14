using IntegrationTests.Clients.MoviesApi.Models;

namespace IntegrationTests.Helpers;

internal class MovieBuilder
{
    private int? _year;
    private double? _rating;

    public MovieBuilder WithYear(int year)
    {
        _year = year;
        return this;
    }

    public MovieBuilder WithRating(double rating)
    {
        _rating = rating;
        return this;
    }

    public MovieBuilder WithoutRating()
    {
        _rating = null;
        return this;
    }

    public Movie Build()
    {
        return new Movie
        {
            Id = Guid.NewGuid(),
            Title = $"Test Movie {Guid.NewGuid()}",
            Description = "This is a test movie.",
            Year = _year ?? Random.Shared.Next(1900, DateTime.UtcNow.Year + 1),
            Rating = _rating
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
