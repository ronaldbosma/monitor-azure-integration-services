namespace FunctionApp.Models;

public class UserRating
{
    public Guid MovieId { get; set; }

    public Guid UserId { get; set; }

    public int Rating { get; set; }
}
