namespace FunctionApp.Models;

public class HealthEntry
{
    public string Name { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Exception { get; set; }
    public Dictionary<string, object> Data { get; set; } = new();
}