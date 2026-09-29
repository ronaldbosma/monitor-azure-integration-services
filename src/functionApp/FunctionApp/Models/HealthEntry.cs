namespace FunctionApp.Models;

public class HealthEntry
{
    public string Status { get; set; } = string.Empty;

    public string? Description { get; set; }

    public Dictionary<string, object> Data { get; set; } = new();

    public TimeSpan Duration { get; set; }
}