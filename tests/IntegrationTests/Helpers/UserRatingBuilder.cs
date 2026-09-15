using IntegrationTests.Clients.UserRatingsApi.Models;

namespace IntegrationTests.Helpers;

internal class UserRatingBuilder
{
    private Guid? _movieId;
    private int? _rating;

    public UserRatingBuilder WithMovieId(Guid movieId)
    {
        _movieId = movieId;
        return this;
    }
    public UserRatingBuilder WithRating(int rating)
    {
        _rating = rating;
        return this;
    }

    public UserRating Build()
    {
        return new UserRating
        {
            MovieId = _movieId ?? Guid.NewGuid(),
            UserId = Guid.NewGuid(),
            Rating = _rating ?? Random.Shared.Next(1, 11)
        };
    }

    public List<UserRating> BuildMany(int count = 3)
    {
        var list = new List<UserRating>();
        for (int i = 0; i < count; i++)
        {
            list.Add(Build());
        }
        return list;
    }
}
