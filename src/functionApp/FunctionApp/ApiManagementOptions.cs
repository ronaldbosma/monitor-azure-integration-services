using System.ComponentModel.DataAnnotations;

namespace FunctionApp;

internal class ApiManagementOptions
{
    public const string SectionKey = "ApiManagement";

    [Required(AllowEmptyStrings = false)]
    [Url]
    public string GatewayUrl { get; set; } = string.Empty;

    [Required(AllowEmptyStrings = false)]
    public string SubscriptionKey { get; set; } = string.Empty;
}
