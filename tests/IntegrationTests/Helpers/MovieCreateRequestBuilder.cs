using IntegrationTests.Clients.MoviesApi.Models;

namespace IntegrationTests.Helpers;

internal class MovieCreateRequestBuilder
{
    public MovieCreateRequest Build()
    {
        return new MovieCreateRequest
        {
            Id = Guid.NewGuid(),
            Title = $"Test Movie {Guid.NewGuid()}",
            Description = "This is a test movie.",
            Year = 2023
        };
    }
}
