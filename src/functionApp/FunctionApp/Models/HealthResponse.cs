using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace FunctionApp.Models;

public class HealthResponse
{
    public string Status { get; set; } = string.Empty;

    public Dictionary<string, HealthEntry> Checks { get; set; } = new();

    public static HealthResponse FromHealthReport(HealthReport report)
    {
        return new HealthResponse
        {
            Status = report.Status.ToString(),
            Checks = report.Entries.ToDictionary(e => e.Key, e => new HealthEntry
            {
                Status = e.Value.Status.ToString(),
                Description = e.Value.Description,
                Data = e.Value.Data.ToDictionary(d => d.Key, d => d.Value),
                Duration = e.Value.Duration
            })
        };
    }
}
