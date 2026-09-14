using System.Net;

using IntegrationTests.Clients.MoviesApi;
using IntegrationTests.Clients.MoviesApi.Models;
using IntegrationTests.Helpers;

namespace IntegrationTests;

[TestClass]
public class MoviesApiTests
{
    private MoviesApiClient _sut = null!;

    [TestInitialize]
    public async Task TestInitialize()
    {
        _sut = await MoviesApiClient.CreateAsync();
    }

    [TestCleanup]
    public void TestCleanup()
    {
        _sut?.Dispose();
    }

    [TestMethod]
    public async Task CreateMovieAsync_ValidRequest_201CreatedWithMovieReturned()
    {
        // Arrange
        var movieCreateRequest = new MovieCreateRequestBuilder().Build();

        // Act
        var result = await _sut.CreateMovieAsync(movieCreateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.Created, result.StatusCode);

        var actualMovie = await result.ReadContentAsAsync<Movie>();
        Assert.AreEquivalent<object>(movieCreateRequest, actualMovie);
    }

    [TestMethod]
    public async Task CreateMovieAsync_MovieWithSameIdAlreadyExists_409ConflictReturned()
    {
        // Arrange
        var movieCreateRequest = new MovieCreateRequestBuilder().Build();

        var result1 = await _sut.CreateMovieAsync(movieCreateRequest);
        Assert.AreEqual(HttpStatusCode.Created, result1.StatusCode);

        // Act
        var result2 = await _sut.CreateMovieAsync(movieCreateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.Conflict, result2.StatusCode);

        var actualErrorResponse = await result2.ReadContentAsAsync<ErrorResponse>();
        Assert.Contains("The specified entity already exists", actualErrorResponse.Message);
    }

    [TestMethod]
    public async Task CreateMovieAsync_AnotherMovieWithSameTitleExists_409ConflictReturned()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var newMovie = new MovieCreateRequestBuilder().Build();
        newMovie.Title = existingMovie.Title; // Set the title to be the same as the existing movie

        // Act
        var result = await _sut.CreateMovieAsync(newMovie);

        // Assert
        Assert.AreEqual(HttpStatusCode.Conflict, result.StatusCode);

        var expectedErrorResponse = new ErrorResponse
        {
            StatusCode = (int)HttpStatusCode.Conflict,
            Message = $"Another movie with the same title already exists."
        };
        var actualErrorResponse = await result.ReadContentAsAsync<ErrorResponse>();
        Assert.AreEquivalent(expectedErrorResponse, actualErrorResponse);
    }

    [TestMethod]
    public async Task GetMovieByIdAsync_ExistingMovie_200OkWithMovieReturned()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(movie);

        // Act
        var result = await _sut.GetMovieByIdAsync(movie.Id);

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, result.StatusCode);

        var actualMovie = await result.ReadContentAsAsync<Movie>();
        Assert.AreEquivalent(movie, actualMovie);
    }

    [TestMethod]
    public async Task GetMovieByIdAsync_UnknownMovie_404NotFoundReturned()
    {
        // Arrange
        var unknownMovieId = Guid.NewGuid();

        // Act
        var result = await _sut.GetMovieByIdAsync(unknownMovieId);

        // Assert
        Assert.AreEqual(HttpStatusCode.NotFound, result.StatusCode);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_ExistingMovie_204NoContentReturnedAndMovieUpdated()
    {
        // Arrange
        var existingMovie = new MovieBuilder().WithYear(2023).WithoutRating().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Title = $"Updated Title {Guid.NewGuid()}",
            Description = "Updated Description",
            Year = 2024,
            Rating = 9.0
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.NoContent, result.StatusCode);

        var updatedMovie = await DataHelper.GetMovieAsync(existingMovie.Id);
        Assert.AreEquivalent<object>(updateRequest, updatedMovie);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_AnotherMovieWithSameTitleExists_409ConflictReturned()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var anotherMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(anotherMovie);

        // Attempt to update the existing movie's title to the same title as another movie
        var updateRequest = new MovieUpdateRequest
        {
            Title = anotherMovie.Title
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.Conflict, result.StatusCode);

        var expectedErrorResponse = new ErrorResponse
        {
            StatusCode = (int)HttpStatusCode.Conflict,
            Message = $"Another movie with the same title already exists."
        };
        var actualErrorResponse = await result.ReadContentAsAsync<ErrorResponse>();
        Assert.AreEquivalent(expectedErrorResponse, actualErrorResponse);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_TitleSpecifiedButNotChanged_MovieUpdatedSuccessfully()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Title = existingMovie.Title
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.NoContent, result.StatusCode);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_OnlyUpdateRating_204NoContentReturnedAndRatingOfMovieUpdated()
    {
        // Arrange
        var existingMovie = new MovieBuilder().WithRating(8.5).Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Rating = 9.0
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.NoContent, result.StatusCode);

        var expectedMovie = existingMovie;
        expectedMovie.Rating = updateRequest.Rating;

        var updatedMovie = await DataHelper.GetMovieAsync(existingMovie.Id);
        Assert.AreEquivalent<object>(expectedMovie, updatedMovie);
    }
}
