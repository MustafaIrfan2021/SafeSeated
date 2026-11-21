using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SafeSeatedBackend.Models;
using SafeSeatedBackend.Data;
using System.Security.Claims;

namespace SafeSeatedBackend.Controllers;

[ApiController]
[Authorize]
[Route("api/documents")]
public class DocumentsController : ControllerBase
{
    private const long MaxFileSizeBytes = 5 * 1024 * 1024;
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".pdf"
    };

    private readonly SafeSeatedDbContext _db;
    private readonly IWebHostEnvironment _environment;

    public DocumentsController(SafeSeatedDbContext db, IWebHostEnvironment environment)
    {
        _db = db;
        _environment = environment;
    }

    [HttpPost]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(MaxFileSizeBytes + 64 * 1024)]
    public async Task<IActionResult> Upload([FromForm] string documentType, IFormFile? file)
    {
        if (file == null || file.Length == 0)
            return FieldError(nameof(file), "Select a file to upload.");
        if (file.Length > MaxFileSizeBytes)
            return FieldError(nameof(file), "File size must not exceed 5 MB.");

        var extension = Path.GetExtension(file.FileName);
        if (!AllowedExtensions.Contains(extension))
            return FieldError(nameof(file), "Only .jpg, .jpeg, .png, and .pdf files are allowed.");

        if (int.TryParse(documentType, out _)
            || !Enum.TryParse<DocumentType>(documentType, ignoreCase: true, out var type)
            || !Enum.IsDefined(type))
        {
            return FieldError(nameof(documentType), "Document type is invalid.");
        }

        var userId = GetUserId();
        var user = await _db.Users.FirstOrDefaultAsync(candidate => candidate.Id == userId);
        if (user == null)
            return Unauthorized();
        if (user.Role is not UserRole.Passenger and not UserRole.Driver)
            return Forbid();
        if (!GetRequiredDocumentTypes(user.Role).Contains(type))
            return FieldError(nameof(documentType), "This document type is not allowed for your account.");

        var originalFileName = Path.GetFileName(file.FileName);
        if (originalFileName.Length > 255)
            return FieldError(nameof(file), "File name must not exceed 255 characters.");

        if (file.ContentType.Length > 100)
            return FieldError(nameof(file), "File content type is too long.");

        var uploadDirectory = GetUploadDirectory();
        Directory.CreateDirectory(uploadDirectory);
        var savedFileName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        var fullPath = Path.Combine(uploadDirectory, savedFileName);
        var relativePath = $"/uploads/{savedFileName}";
        var document = new UserDocument
        {
            UserId = userId,
            DocumentType = type,
            StoredFilePath = relativePath,
            OriginalFileName = originalFileName,
            ContentType = file.ContentType,
            Status = DocumentStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };
        try
        {
            await using (var stream = new FileStream(fullPath, FileMode.CreateNew, FileAccess.Write, FileShare.None))
                await file.CopyToAsync(stream);

            _db.UserDocuments.Add(document);
            user.Status = UserStatus.Pending;
            await _db.SaveChangesAsync();
        }
        catch
        {
            if (System.IO.File.Exists(fullPath))
                System.IO.File.Delete(fullPath);
            throw;
        }

        return Created($"/api/documents/me", new
        {
            id = document.Id,
            documentType = document.DocumentType.ToString(),
            status = document.Status.ToString(),
            uploadedAt = document.CreatedAt,
            fileUrl = GetFileUrl(document.StoredFilePath)
        });
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyDocuments()
    {
        var userId = GetUserId();
        var documents = await _db.UserDocuments
            .Where(document => document.UserId == userId)
            .OrderByDescending(document => document.CreatedAt)
            .ThenByDescending(document => document.Id)
            .Select(document => new
            {
                document.Id,
                document.DocumentType,
                document.Status,
                UploadedAt = document.CreatedAt,
                document.OriginalFileName,
                document.RejectionReason,
                document.StoredFilePath
            })
            .ToListAsync();

        return Ok(documents.Select(document => new
        {
            document.Id,
            documentType = document.DocumentType.ToString(),
            status = document.Status.ToString(),
            document.UploadedAt,
            document.OriginalFileName,
            document.RejectionReason,
            fileUrl = GetFileUrl(document.StoredFilePath)
        }));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteMyPendingDocument(Guid id)
    {
        var userId = GetUserId();
        var document = await _db.UserDocuments
            .FirstOrDefaultAsync(item => item.Id == id && item.UserId == userId);
        if (document == null)
            return NotFound();
        if (document.Status != DocumentStatus.Pending)
            return Conflict(new ProblemDetails
            {
                Status = StatusCodes.Status409Conflict,
                Title = "Only pending documents can be deleted."
            });

        _db.UserDocuments.Remove(document);
        await _db.SaveChangesAsync();
        System.IO.File.Delete(GetStoredFileFullPath(document.StoredFilePath));
        return NoContent();
    }

    [HttpGet("/api/admin/documents")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetDocuments([FromQuery] string? status)
    {
        DocumentStatus? statusFilter = null;
        if (status != null)
        {
            if (int.TryParse(status, out _)
                || !Enum.TryParse<DocumentStatus>(status, ignoreCase: true, out var parsedStatus)
                || !Enum.IsDefined(parsedStatus))
            {
                return FieldError(nameof(status), "Status must be Pending, Approved, or Rejected.");
            }

            statusFilter = parsedStatus;
        }

        var query = _db.UserDocuments.Include(document => document.User).AsQueryable();
        if (statusFilter.HasValue)
            query = query.Where(document => document.Status == statusFilter.Value);

        var documents = await query.OrderByDescending(document => document.CreatedAt).ToListAsync();
        return Ok(documents.Select(document => new
        {
            document.Id,
            document.UserId,
            user = new { document.User.FullName, document.User.Email, role = document.User.Role.ToString() },
            documentType = document.DocumentType.ToString(),
            status = document.Status.ToString(),
            uploadedAt = document.CreatedAt,
            document.OriginalFileName,
            document.RejectionReason,
            fileUrl = GetFileUrl(document.StoredFilePath)
        }));
    }

    [HttpPatch("/api/admin/documents/{id:guid}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateDocumentStatus(Guid id, UpdateDocumentStatusRequest request)
    {
        if (int.TryParse(request.Status, out _)
            || !Enum.TryParse<DocumentStatus>(request.Status, ignoreCase: true, out var status)
            || status is not DocumentStatus.Approved and not DocumentStatus.Rejected)
        {
            return FieldError(nameof(request.Status), "Status must be Approved or Rejected.");
        }

        var document = await _db.UserDocuments.FindAsync(id);
        if (document == null)
            return NotFound();
        if (document.Status != DocumentStatus.Pending)
            return Conflict(new ProblemDetails
            {
                Status = StatusCodes.Status409Conflict,
                Title = "Only pending documents can be reviewed."
            });

        var user = await _db.Users.FirstOrDefaultAsync(candidate => candidate.Id == document.UserId);
        if (user == null)
            return NotFound(new ProblemDetails { Status = StatusCodes.Status404NotFound, Title = "Document owner not found." });

        document.Status = status;
        document.ReviewedByAdminId = GetUserId();
        document.ReviewedAt = DateTime.UtcNow;
        await UpdateVerificationStatusAsync(user);
        await _db.SaveChangesAsync();

        return Ok(new
        {
            id = document.Id,
            status = document.Status.ToString(),
            verificationStatus = user.Status.ToString()
        });
    }

    private async Task UpdateVerificationStatusAsync(User user)
    {
        var requiredTypes = GetRequiredDocumentTypes(user.Role);
        var latestDocuments = await _db.UserDocuments
            .Where(document => document.UserId == user.Id)
            .OrderByDescending(document => document.CreatedAt)
            .ThenByDescending(document => document.Id)
            .ToListAsync();
        var latestByType = latestDocuments
            .GroupBy(document => document.DocumentType)
            .ToDictionary(group => group.Key, group => group.First());

        if (requiredTypes.Any(type => latestByType.TryGetValue(type, out var document)
            && document.Status == DocumentStatus.Rejected))
        {
            user.Status = UserStatus.Rejected;
        }
        else if (requiredTypes.All(type => latestByType.TryGetValue(type, out var document)
            && document.Status == DocumentStatus.Approved))
        {
            user.Status = UserStatus.Verified;
        }
        else
        {
            user.Status = UserStatus.Pending;
        }
    }

    private Guid GetUserId() =>
        Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : Guid.Empty;

    private string GetUploadDirectory() =>
        Path.Combine(_environment.ContentRootPath, "wwwroot", "uploads");

    private string GetFileUrl(string relativePath) =>
        $"{Request.Scheme}://{Request.Host}{relativePath}";

    private string GetStoredFileFullPath(string relativePath)
    {
        const string prefix = "/uploads/";
        var fileName = relativePath.StartsWith(prefix, StringComparison.Ordinal)
            ? relativePath[prefix.Length..]
            : string.Empty;
        if (string.IsNullOrWhiteSpace(fileName) || Path.GetFileName(fileName) != fileName)
            throw new InvalidOperationException("Stored document path is invalid.");

        return Path.Combine(GetUploadDirectory(), fileName);
    }

    private IActionResult FieldError(string field, string message) =>
        BadRequest(new ValidationProblemDetails(new Dictionary<string, string[]> { [field] = [message] })
        {
            Status = StatusCodes.Status400BadRequest
        });

    internal static DocumentType[] GetRequiredDocumentTypes(UserRole role) =>
        role == UserRole.Passenger
            ? [DocumentType.CnicFront, DocumentType.CnicBack, DocumentType.StudentCard]
            : [DocumentType.CnicFront, DocumentType.CnicBack, DocumentType.DrivingLicence,
                DocumentType.VehicleRegistration, DocumentType.VehiclePhoto];
}

public sealed class UpdateDocumentStatusRequest
{
    public string Status { get; set; } = string.Empty;
}
