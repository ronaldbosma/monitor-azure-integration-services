using Azure;

using IntegrationTests.Clients;
using IntegrationTests.Helpers;

namespace IntegrationTests;

/// <summary>
/// Integration tests for the "Recalculate Rating for All Movies" workflow in the Logic App.
/// </summary>
[TestClass]
public class RecalculateRatingForAllMoviesWorkflowTests
{
    [TestMethod]
    public async Task RunAsync_MoviesWithAndWithoutUserRatings_MovieRatingUpdatedAccordingly()
    {
        // Arrange
        using var sut = LogicAppWorkflowClient.CreateClient("recalculate-rating-for-all-movies", "Recurrence");

        // Checks scenario where a movie has no rating but has one new user rating, so the rating should be set to that user rating
        var movieWithoutRatingAndOneNewUserRating = new MovieBuilder().WithoutRating().Build();
        await DataHelper.CreateMovieWithUserRatingsAsync(
            movieWithoutRatingAndOneNewUserRating,
            new UserRatingBuilder().WithMovieId(movieWithoutRatingAndOneNewUserRating.Id).WithRating(8).BuildMany(1)
        );

        // Checks that new rating is calculated correctly and overwrites the old rating
        var movieWithRatingAndMultipleNewRatings = new MovieBuilder().WithRating(10).Build();
        await DataHelper.CreateMovieWithUserRatingsAsync(
            movieWithRatingAndMultipleNewRatings,
            [
                // These ratings average to 7.3
                new UserRatingBuilder().WithMovieId(movieWithRatingAndMultipleNewRatings.Id).WithRating(6).Build(),
                new UserRatingBuilder().WithMovieId(movieWithRatingAndMultipleNewRatings.Id).WithRating(8).Build(),
                new UserRatingBuilder().WithMovieId(movieWithRatingAndMultipleNewRatings.Id).WithRating(8).Build()
            ]
        );

        // Checks scenario where a movie has no user ratings and no rating, so the rating should remain null
        var movieWithoutUserRatings = new MovieBuilder().WithoutRating().Build();
        await DataHelper.CreateMovieAsync(movieWithoutUserRatings);

        // Act
        var result = await sut.RunAsync(WaitUntil.Completed);

        // Assert
        await AssertMovieRatingAsync(movieWithoutRatingAndOneNewUserRating.Id, 8);
        await AssertMovieRatingAsync(movieWithRatingAndMultipleNewRatings.Id, 7.3);
        await AssertMovieRatingAsync(movieWithoutUserRatings.Id, null);
    }

    private async Task AssertMovieRatingAsync(Guid movieId, double? expectedRating)
    {
        // Assert that the movie's rating is updated to the expected value, retrying for a few seconds in case the workflow hasn't completed yet
        double? actualRating = null;
        for (int i = 0; i < 20; i++)
        {
            var movie = await DataHelper.GetMovieAsync(movieId);
            actualRating = movie.Rating;
            if (actualRating == expectedRating)
            {
                break;
            }

            Thread.Sleep(i * 200);
        }

        Assert.AreEqual(expectedRating, actualRating, $"Unexpected rating for movie with ID {movieId}");
    }
}
