using Azure;
using Azure.Data.Tables;

namespace FunctionApp.Models;

public class UserRatingEntity : ITableEntity
{
    public string PartitionKey { get; set; } = default!;

    public string RowKey { get; set; } = default!;

    public int Rating { get; set; }

    public ETag ETag { get; set; }

    public DateTimeOffset? Timestamp { get; set; }
}
