namespace FunctionApp.Models;

using System.ComponentModel.DataAnnotations;

public class UserRating
{
    [Required]
    public Guid MovieId { get; set; }

    [Required]
    public Guid UserId { get; set; }

    [Required]
    [Range(1, 10, ErrorMessage = "Rating must be between 1 and 10")]
    public int Rating { get; set; }
}
