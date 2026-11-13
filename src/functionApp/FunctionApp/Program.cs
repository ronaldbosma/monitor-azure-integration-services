using FunctionApp;

using Microsoft.Azure.Functions.Worker.Builder;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

builder.Logging.AddOpenTelemetry(logging =>
{
    logging.IncludeFormattedMessage = true;
    logging.IncludeScopes = true;
});

builder.Services.ConfigureOpenTelemetry();
builder.Services.RegisterDependencies(builder.Configuration);
builder.Services.ConfigureHealthChecks();

builder.Build().Run();
