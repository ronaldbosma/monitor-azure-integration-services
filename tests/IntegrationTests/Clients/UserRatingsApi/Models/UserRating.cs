namespace IntegrationTests.Clients.UserRatingsApi.Models;

/// <summary>
/// A user's rating for a movie.
/// </summary>
internal class UserRating
{
    public required Guid MovieId { get; set; }
    public required Guid UserId { get; set; }
    public required int Rating { get; set; }
}
