using Azure;

using IntegrationTests.Clients;
using IntegrationTests.Clients.UserRatingsApi.Models;
using IntegrationTests.Configuration;
using IntegrationTests.Helpers;

namespace IntegrationTests;

[TestClass]
public class RecalculateRatingForAllMoviesWorkflowTests
{
    private static LogicAppWorkflowClient WorkflowClient = null!;

    [ClassInitialize]
    public static void ClassInitialize(TestContext context)
    {
        var config = TestConfiguration.Load();

        // Reuse the same Logic App workflow client so we don't have to fetch the callback URL multiple times
        WorkflowClient = new LogicAppWorkflowClient(
            config.AzureTenantId,
            config.AzureSubscriptionId,
            config.AzureResourceGroup,
            config.AzureLogicAppName,
            "recalculate-rating-for-all-movies",
            "Recurrence"
        );
    }

    [ClassCleanup]
    public static void ClassCleanup()
    {
        WorkflowClient?.Dispose();
    }

    [TestMethod]
    public async Task RunAsync_MoviesWithAndWithoutUserRatings_MovieRatingUpdatedAccordingly()
    {
        // Arrange

        // Checks scenario where a movie has no rating but has one new user rating, so the rating should be set to that user rating
        var movieWithoutRatingAndOneNewUserRating = new MovieBuilder().WithoutRating().Build();
        var userRatingForMovieWithoutRatingAndOneNewUserRating = new UserRatingBuilder().WithMovieId(movieWithoutRatingAndOneNewUserRating.Id).Build();
        await DataHelper.CreateMovieWithUserRatingsAsync(movieWithoutRatingAndOneNewUserRating, [userRatingForMovieWithoutRatingAndOneNewUserRating]);

        // Checks that new rating is calculated correctly and overwrites the old rating
        var movieWithRatingAndMultipleNewRatings = new MovieBuilder().WithRating(10).Build();
        var userRatings = new List<UserRating>
        {
            // These ratings average to 7.3
            new UserRatingBuilder().WithMovieId(movieWithRatingAndMultipleNewRatings.Id).WithRating(6).Build(),
            new UserRatingBuilder().WithMovieId(movieWithRatingAndMultipleNewRatings.Id).WithRating(8).Build(),
            new UserRatingBuilder().WithMovieId(movieWithRatingAndMultipleNewRatings.Id).WithRating(8).Build()
        };
        await DataHelper.CreateMovieWithUserRatingsAsync(movieWithRatingAndMultipleNewRatings, userRatings);

        // Checks scenario where a movie has no user ratings and no rating, so the rating should remain null
        var movieWithoutUserRatings = new MovieBuilder().WithoutRating().Build();
        await DataHelper.CreateMovieAsync(movieWithoutUserRatings);

        // Act
        var result = await WorkflowClient.RunAsync(WaitUntil.Completed);

        // Assert
        await AssertMovieRatingAsync(movieWithoutRatingAndOneNewUserRating.Id, userRatingForMovieWithoutRatingAndOneNewUserRating.Rating);
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
