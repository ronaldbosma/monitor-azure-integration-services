using System.Net.Http.Json;

namespace IntegrationTests.Helpers;

internal static class HttpResponseMessageExtensions
{
    public static async Task<T> ReadContentAsAsync<T>(this HttpResponseMessage? response)
    {
        ArgumentNullException.ThrowIfNull(response);

        return await response.Content.ReadFromJsonAsync<T>(JsonSerializerHelper.JsonSerializerOptions)
            ?? throw new InvalidOperationException("Response content is null");
    }
}
