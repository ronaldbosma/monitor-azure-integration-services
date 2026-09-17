using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace FunctionApp.HealthChecks;

public class HealthFunction
{
    private readonly HealthCheckService _healthService;

    public HealthFunction(HealthCheckService healthService)
    {
        _healthService = healthService;
    }

    [Function("HealthFunction")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "health")] HttpRequest req)
    {
        var healthResult = await _healthService.CheckHealthAsync();

        var responseContent = new
        {
            status = healthResult.Status.ToString(),
            entries = healthResult.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                exception = e.Value.Exception?.ToString(),
                data = e.Value.Data.ToDictionary(d => d.Key, d => d.Value)
            })
        };
        return new JsonResult(responseContent)
        {
            StatusCode = healthResult.Status == HealthStatus.Healthy ? 200 : 503
        };
    }
}