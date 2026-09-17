using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace FunctionApp.Models;

public class HealthResponse
{
    public string Status { get; set; } = string.Empty;

    public List<HealthEntry> Entries { get; set; } = [];

    public static HealthResponse FromHealthReport(HealthReport report)
    {
        return new HealthResponse
        {
            Status = report.Status.ToString(),
            Entries = report.Entries.Select(e => new HealthEntry
            {
                Name = e.Key,
                Status = e.Value.Status.ToString(),
                Description = e.Value.Description,
                Exception = e.Value.Exception?.ToString(),
                Data = e.Value.Data.ToDictionary(d => d.Key, d => d.Value)
            }).ToList()
        };
    }
}
