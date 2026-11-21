using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Models;

namespace SafeSeatedBackend.Controllers;

[ApiController]
[Route("api/complaints")]
[Authorize]
public sealed class ComplaintsController : ControllerBase
{
    private readonly SafeSeatedDbContext _db;

    public ComplaintsController(SafeSeatedDbContext db)
    {
        _db = db;
    }

    [HttpPost]
    public async Task<IActionResult> CreateComplaint(
        CreateComplaintRequest request,
        CancellationToken cancellationToken)
    {
        var reporterId = GetUserId();
        if (reporterId == Guid.Empty)
            return Unauthorized();
        if (string.IsNullOrWhiteSpace(request.Description))
            return FieldError(nameof(request.Description), "Description is required.");

        var reporterExists = await _db.Users.AnyAsync(user => user.Id == reporterId, cancellationToken);
        if (!reporterExists)
            return Unauthorized();
        if (request.RideId.HasValue &&
            !await _db.Rides.AnyAsync(ride => ride.Id == request.RideId.Value, cancellationToken))
        {
            return FieldError(nameof(request.RideId), "Ride was not found.");
        }

        var complaint = new Complaint
        {
            PassengerId = reporterId,
            RideId = request.RideId,
            Description = request.Description.Trim(),
            Status = ComplaintStatus.Open,
            CreatedAt = DateTime.UtcNow
        };
        _db.Complaints.Add(complaint);
        await _db.SaveChangesAsync(cancellationToken);

        return Created("/api/complaints/me", ToComplaintResponse(complaint));
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyComplaints(CancellationToken cancellationToken)
    {
        var reporterId = GetUserId();
        var complaints = await _db.Complaints
            .Where(complaint => complaint.PassengerId == reporterId)
            .OrderByDescending(complaint => complaint.CreatedAt)
            .ToListAsync(cancellationToken);
        return Ok(complaints.Select(ToComplaintResponse));
    }

    private Guid GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : Guid.Empty;

    private IActionResult FieldError(string field, string message) =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]> { [field] = [message] })
        {
            Status = StatusCodes.Status400BadRequest
        });

    private static object ToComplaintResponse(Complaint complaint) => new
    {
        complaint.Id,
        reporterId = complaint.PassengerId,
        complaint.RideId,
        complaint.Description,
        status = complaint.Status.ToString(),
        complaint.CreatedAt
    };
}

/// <summary>Fields used to submit a complaint.</summary>
public sealed class CreateComplaintRequest
{
    public Guid? RideId { get; set; }

    [Required, StringLength(1000)]
    public string Description { get; set; } = string.Empty;
}
