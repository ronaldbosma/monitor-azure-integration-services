using IntegrationTests.Clients.MoviesApi;
using IntegrationTests.Clients.MoviesApi.Models;
using IntegrationTests.Clients.UserRatingsApi;
using IntegrationTests.Clients.UserRatingsApi.Models;

namespace IntegrationTests.Helpers;

/// <summary>
/// Helper class for creating data in the data store for integration tests.
/// It's currently reusing the various APIs on API Management, but could also be implemented to directly create data in the data store if needed.
/// </summary>
internal static class DataHelper
{
    public static async Task CreateMoviesAsync(IEnumerable<Movie> movies)
    {
        foreach (var movie in movies)
        {
            await DataHelper.CreateMovieAsync(movie);
        }
    }

    public static async Task CreateMovieAsync(Movie movie)
    {
        using var client = await MoviesApiClient.CreateClientAsync();

        // First, create the movie
        Console.WriteLine($"Creating movie: {movie.Title} ({movie.Year})");

        var createRequest = MovieCreateRequest.FromMovie(movie);
        var createResponse = await client.CreateMovieAsync(createRequest);
        createResponse.EnsureSuccessStatusCode();

        // If a rating is provided, update the movie with the rating (we can't specify it during creation)
        if (movie.Rating.HasValue)
        {
            Console.WriteLine($"Updating movie rating: {movie.Rating}");

            var updateRequest = new MovieUpdateRequest
            {
                Rating = movie.Rating.Value
            };
            var updateResponse = await client.UpdateMovieAsync(movie.Id, updateRequest, createResponse.Headers.GetValues("ETag").FirstOrDefault());
            updateResponse.EnsureSuccessStatusCode();
        }
    }

    public static async Task<Movie> GetMovieAsync(Guid movieId)
    {
        using var client = await MoviesApiClient.CreateClientAsync();
        var response = await client.GetMovieByIdAsync(movieId);
        response.EnsureSuccessStatusCode();
        return await response.ReadContentAsAsync<Movie>();
    }

    public static async Task<bool> DoesMovieExist(Guid movieId)
    {
        using var client = await MoviesApiClient.CreateClientAsync();
        var response = await client.GetMovieByIdAsync(movieId);

        if (response.StatusCode == System.Net.HttpStatusCode.OK)
        {
            return true;
        }
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return false;
        }

        throw new InvalidOperationException($"Unexpected status code {response.StatusCode} when checking if movie exists.");
    }

    public static async Task CreateUserRatingsAsync(IEnumerable<UserRating> userRatings)
    {
        foreach (var userRating in userRatings)
        {
            await CreateUserRatingAsync(userRating);
        }
    }

    public static async Task CreateUserRatingAsync(UserRating userRating)
    {
        using var client = await UserRatingsApiClient.CreateClientAsync();

        Console.WriteLine($"Creating user rating for movie: {userRating.MovieId}, user: {userRating.UserId}, rating: {userRating.Rating}");

        var response = await client.InsertOrUpdateUserRatingAsync(userRating);
        response.EnsureSuccessStatusCode();
    }

    public static async Task<UserRating> GetUserRatingAsync(Guid movieId, Guid userId)
    {
        using var client = await UserRatingsApiClient.CreateClientAsync();

        var response = await client.GetUserRatingsAsync(movieId);
        response.EnsureSuccessStatusCode();

        var ratings = await response.ReadContentAsAsync<List<UserRating>>();

        return ratings.SingleOrDefault(r => r.UserId == userId)
            ?? throw new InvalidOperationException($"User rating not found for movieId: {movieId}, userId: {userId}");
    }

    public static async Task<bool> DoUserRatingsExistForMovieAsync(Guid movieId)
    {
        using var client = await UserRatingsApiClient.CreateClientAsync();

        var response = await client.GetUserRatingsAsync(movieId);
        response.EnsureSuccessStatusCode();

        var ratings = await response.ReadContentAsAsync<List<UserRating>>();

        return ratings.Count > 0;
    }
}
