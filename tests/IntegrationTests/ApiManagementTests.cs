using System.Net;

using IntegrationTests.Clients;
using IntegrationTests.Configuration;

namespace IntegrationTests;

[TestClass]
public sealed class ApiManagementTests
{
    private static HttpClient? s_httpClient;

    [ClassInitialize]
    public static void ClassInitialize(TestContext context)
    {
        var config = TestConfiguration.Load();
        s_httpClient = new IntegrationTestHttpClient(config.AzureApiManagementGatewayUrl);
    }

    [ClassCleanup]
    public static void ClassCleanup()
    {
        s_httpClient?.Dispose();
    }

    [TestMethod]
    public async Task GetApimStatusEndpoint_NoArguments_200OkReturned()
    {
        // Act
        var response = await s_httpClient!.GetAsync("internal-status-0123456789abcdef");

        // Assert
        Assert.AreEqual(HttpStatusCode.OK, response.StatusCode, "Unexpected status code returned");
    }
}