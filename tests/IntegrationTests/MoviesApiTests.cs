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
        _sut = await MoviesApiClient.CreateClientAsync();
    }

    [TestCleanup]
    public void TestCleanup()
    {
        _sut?.Dispose();
    }

    [TestMethod]
    public async Task GetMoviesAsync_NoFilterSpecified_MoviesReturned()
    {
        // Arrange
        var movies = new MovieBuilder().BuildMany();
        await DataHelper.CreateMoviesAsync(movies);

        // Act
        var result = await _sut.GetMoviesAsync();

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, result.StatusCode);

        var actualMovies = await result.ReadContentAsAsync<List<MovieSummary>>();
        Assert.IsGreaterThanOrEqualTo(movies.Count, actualMovies.Count);
        
        foreach (var expectedMovieSummary in movies.Select(MovieSummary.FromMovie))
        {
            var actualMovieSummary = actualMovies.SingleOrDefault(m => m.Id == expectedMovieSummary.Id);
            Assert.IsNotNull(actualMovieSummary);
            Assert.AreEquivalent(expectedMovieSummary, actualMovieSummary);
        }
    }

    [TestMethod]
    public async Task GetMoviesAsync_ExistingTitleSpecified_200OkReturnedWithOneMovieWithTheSpecifiedTitle()
    {
        // Arrange
        var movies = new MovieBuilder().BuildMany();
        await DataHelper.CreateMoviesAsync(movies);

        var expectedMovieSummary = MovieSummary.FromMovie(movies[1]);

        // Act
        var result = await _sut.GetMoviesAsync(expectedMovieSummary.Title);

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, result.StatusCode);

        var actualMovies = await result.ReadContentAsAsync<List<MovieSummary>>();
        Assert.AreEqual(1, actualMovies.Count);
        Assert.AreEquivalent(expectedMovieSummary, actualMovies[0]);
    }

    [TestMethod]
    public async Task GetMoviesAsync_UnknownTitleSpecified_200OkReturnedWithoutMovies()
    {
        // Arrange
        var movies = new MovieBuilder().BuildMany();
        await DataHelper.CreateMoviesAsync(movies);

        var unknownTitle = $"Unknown Title {Guid.NewGuid()}";

        // Act
        var result = await _sut.GetMoviesAsync(unknownTitle);

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, result.StatusCode);

        var actualMovies = await result.ReadContentAsAsync<List<MovieSummary>>();
        Assert.AreEqual(0, actualMovies.Count);
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
    public async Task CreateMovieAsync_TitleIsEmptyString_400BadRequestReturned()
    {
        // Arrange
        var movieCreateRequest = new MovieCreateRequestBuilder().Build();
        movieCreateRequest.Title = string.Empty;

        // Act
        var result = await _sut.CreateMovieAsync(movieCreateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task CreateMovieAsync_DescriptionIsEmptyString_400BadRequestReturned()
    {
        // Arrange
        var movieCreateRequest = new MovieCreateRequestBuilder().Build();
        movieCreateRequest.Description = string.Empty;

        // Act
        var result = await _sut.CreateMovieAsync(movieCreateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task CreateMovieAsync_YearIsTooLow_400BadRequestReturned()
    {
        // Arrange
        var movieCreateRequest = new MovieCreateRequestBuilder().Build();
        movieCreateRequest.Year = 999; // too low, 1000 is the minimum valid year

        // Act
        var result = await _sut.CreateMovieAsync(movieCreateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task CreateMovieAsync_YearIsTooHigh_400BadRequestReturned()
    {
        // Arrange
        var movieCreateRequest = new MovieCreateRequestBuilder().Build();
        movieCreateRequest.Year = 10000; // too high, 9999 is the maximum valid year

        // Act
        var result = await _sut.CreateMovieAsync(movieCreateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
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
    public async Task UpdateMovieAsync_UnknownMovie_404NotFoundReturned()
    {
        // Arrange
        var unknownMovieId = Guid.NewGuid();

        var updateRequest = new MovieUpdateRequest();

        // Act
        var result = await _sut.UpdateMovieAsync(unknownMovieId, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.NotFound, result.StatusCode);
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

    [TestMethod]
    public async Task UpdateMovieAsync_TitleIsEmptyString_400BadRequestReturned()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Title = string.Empty
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_DescriptionIsEmptyString_400BadRequestReturned()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Description = string.Empty
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_YearIsTooLow_400BadRequestReturned()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Year = 999 // too low, 1000 is the minimum valid year
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_YearIsTooHigh_400BadRequestReturned()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Year = 10000 // too high, 9999 is the maximum valid year
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_RatingIsTooLow_400BadRequestReturned()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Rating = -1.0 // too low, 0.0 is the minimum valid rating
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task UpdateMovieAsync_RatingIsTooHigh_400BadRequestReturned()
    {
        // Arrange
        var existingMovie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(existingMovie);

        var updateRequest = new MovieUpdateRequest
        {
            Rating = 11.0 // too high, 10.0 is the maximum valid rating
        };

        // Act
        var result = await _sut.UpdateMovieAsync(existingMovie.Id, updateRequest);

        // Assert
        Assert.AreEqual(HttpStatusCode.BadRequest, result.StatusCode);
    }

    [TestMethod]
    public async Task DeleteMovieAsync_ExistingMovie_204NoContentReturnedAndMovieDeleted()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(movie);

        // Act
        var result = await _sut.DeleteMovieAsync(movie.Id);

        // Assert
        Assert.AreEqual(HttpStatusCode.NoContent, result.StatusCode);

        bool movieExists = await DataHelper.DoesMovieExistAsync(movie.Id);
        Assert.IsFalse(movieExists);
    }

    [TestMethod]
    public async Task DeleteMovieAsync_UnknownMovie_404NotFoundReturned()
    {
        // Arrange
        var unknownMovieId = Guid.NewGuid();

        // Act
        var result = await _sut.DeleteMovieAsync(unknownMovieId);

        // Assert
        Assert.AreEqual(HttpStatusCode.NotFound, result.StatusCode);
    }

    [TestMethod]
    public async Task DeleteMovieAsync_MovieWithUserRatings_UserRatingsForMovieDeleted()
    {
        // Arrange
        var movie = new MovieBuilder().Build();
        await DataHelper.CreateMovieAsync(movie);

        var userRatings = new UserRatingBuilder().WithMovieId(movie.Id).BuildMany();
        await DataHelper.CreateUserRatingsAsync(userRatings);

        // Act
        var result = await _sut.DeleteMovieAsync(movie.Id);

        // Assert
        Assert.AreEqual(HttpStatusCode.NoContent, result.StatusCode);

        // Verify that user ratings for the deleted movie are also deleted
        // Because this is an asynchronous operation, we will check for the existence of user ratings multiple times with a delay in between to allow for eventual consistency.
        bool userRatingsExist = true;
        for (int i = 0; i < 10; i++)
        {
            userRatingsExist = await DataHelper.DoUserRatingsExistForMovieAsync(movie.Id);
            if (!userRatingsExist)
            {
                break;
            }

            Thread.Sleep(i * 200);
        }

        Assert.IsFalse(userRatingsExist, "User ratings for the deleted movie should be deleted.");
    }
}
