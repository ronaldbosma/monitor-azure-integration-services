using System.Text.Json;
using System.Text.Json.Serialization;

namespace IntegrationTests.Helpers;

/// <summary>
/// Provides helper methods for JSON serialization and deserialization with predefined options.
/// </summary>
internal class JsonSerializerHelper
{
    public static readonly JsonSerializerOptions JsonSerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };
}
