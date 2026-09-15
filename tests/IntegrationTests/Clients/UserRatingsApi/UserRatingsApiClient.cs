using System.Net.Http.Json;

using IntegrationTests.Clients.UserRatingsApi.Models;
using IntegrationTests.Configuration;
using IntegrationTests.Helpers;

namespace IntegrationTests.Clients.UserRatingsApi;

/// <summary>
/// Client for interacting with the User Ratings API exposed through Azure API Management.
/// </summary>
internal class UserRatingsApiClient : IDisposable
{
    private const string SubscriptionKeyHeaderName = "Ocp-Apim-Subscription-Key";

    private readonly IntegrationTestHttpClient _httpClient;

    public UserRatingsApiClient(Uri baseAddress, string subscriptionKey)
    {
        _httpClient = new IntegrationTestHttpClient(baseAddress);
        _httpClient.DefaultRequestHeaders.Add(SubscriptionKeyHeaderName, subscriptionKey);
    }

    /// <summary>
    /// Creates a new instance of the UserRatingsApiClient, loading configuration and retrieving the subscription key from Azure Key Vault.
    /// </summary>
    /// <returns>A task that represents the asynchronous operation. The task result contains the created UserRatingsApiClient instance.</returns>
    public static async Task<UserRatingsApiClient> CreateClientAsync()
    {
        var config = TestConfiguration.Load();

        var keyVaultClient = new KeyVaultClient(config.AzureKeyVaultUri);
        var apimSubscriptionKey = await keyVaultClient.GetSecretValueAsync("integration-tests-apim-subscription-key");

        return new UserRatingsApiClient(config.AzureApiManagementGatewayUrl, apimSubscriptionKey);
    }

    /// <summary>
    /// Gets all user ratings for the specified movie.
    /// </summary>
    public async Task<HttpResponseMessage> GetUserRatingsAsync(Guid movieId)
    {
        return await _httpClient.GetAsync($"/user-ratings?movie-id={movieId}");
    }

    /// <summary>
    /// Inserts or updates a user's rating for a movie.
    /// </summary>
    public async Task<HttpResponseMessage> InsertOrUpdateUserRatingAsync(UserRating userRating)
    {
        return await _httpClient.PutAsJsonAsync("/user-ratings", userRating, options: JsonSerializerHelper.JsonSerializerOptions);
    }

    public void Dispose()
    {
        _httpClient.Dispose();
        GC.SuppressFinalize(this);
    }
}
