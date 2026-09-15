using System.Net;

using IntegrationTests.Clients.UserRatingsApi;
using IntegrationTests.Clients.UserRatingsApi.Models;
using IntegrationTests.Helpers;

namespace IntegrationTests;

/// <summary>
/// Integration tests for the User Ratings API in API Management.
/// </summary>
[TestClass]
public class UserRatingsApiTests
{
    private UserRatingsApiClient _sut = null!;

    [TestInitialize]
    public async Task TestInitialize()
    {
        _sut = await UserRatingsApiClient.CreateClientAsync();
    }

    [TestCleanup]
    public void TestCleanup()
    {
        _sut?.Dispose();
    }

    [TestMethod]
    public async Task GetUserRatingsAsync_UserRatingsExistForMovie_200OkReturnedWithRatings()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        var userRatings = new UserRatingBuilder().WithMovieId(movie.Id).BuildMany();

        await DataHelper.CreateMovieWithUserRatingsAsync(movie, userRatings);

        // Act
        var result = await _sut.GetUserRatingsAsync(movie.Id);

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, result.StatusCode);

        var actualRatings = await result.ReadContentAsAsync<List<UserRating>>();
        Assert.AreEqual(userRatings.Count, actualRatings.Count);
        Assert.AreEquivalent(userRatings.OrderBy(r => r.UserId), actualRatings.OrderBy(r => r.UserId));
    }

    [TestMethod]
    public async Task GetUserRatingsAsync_NoRatingsExistForMovie_200OkReturnedWithoutRatings()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(movie);

        // Act
        var result = await _sut.GetUserRatingsAsync(movie.Id);

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, result.StatusCode);

        var actualRatings = await result.ReadContentAsAsync<List<UserRating>>();
        Assert.AreEqual(0, actualRatings.Count);
    }

    [TestMethod]
    public async Task InsertOrUpdateUserRatingAsync_ValidRequest_204NoContentReturnedAndRatingReturnedOnGet()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(movie);

        var userRating = new UserRatingBuilder().WithMovieId(movie.Id).Build();

        // Act
        var result = await _sut.InsertOrUpdateUserRatingAsync(userRating);

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, result.StatusCode);

        var actualRating = await DataHelper.GetUserRatingAsync(movie.Id, userRating.UserId);
        Assert.AreEquivalent(userRating, actualRating);
    }

    [TestMethod]
    public async Task InsertOrUpdateUserRatingAsync_UpdateExistingRating_204NoContentReturnedAndRatingUpdated()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        var existingUserRating = new UserRatingBuilder().WithMovieId(movie.Id).WithRating(2).Build();
        await DataHelper.CreateMovieWithUserRatingsAsync(movie, [existingUserRating]);

        var updatedUserRating = new UserRating
        {
            MovieId = existingUserRating.MovieId,
            UserId = existingUserRating.UserId,
            Rating = 5
        };

        // Act
        var result = await _sut.InsertOrUpdateUserRatingAsync(updatedUserRating);

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, result.StatusCode);

        var actualRating = await DataHelper.GetUserRatingAsync(movie.Id, existingUserRating.UserId);
        Assert.AreEquivalent(updatedUserRating, actualRating);
        Assert.AreNotEquivalent(existingUserRating, actualRating);
    }

    [TestMethod]
    public async Task InsertOrUpdateUserRatingAsync_RatingIsTooLow_400BadRequestReturned()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(movie);

        var userRating = new UserRatingBuilder()
            .WithMovieId(movie.Id)
            .WithRating(0) // too low, should be between 1 and 10
            .Build();

        // Act
        var result = await _sut.InsertOrUpdateUserRatingAsync(userRating);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task InsertOrUpdateUserRatingAsync_RatingIsTooHigh_400BadRequestReturned()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(movie);

        var userRating = new UserRatingBuilder()
            .WithMovieId(movie.Id)
            .WithRating(11) // too high, should be between 1 and 10
            .Build();

        // Act
        var result = await _sut.InsertOrUpdateUserRatingAsync(userRating);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }
}
