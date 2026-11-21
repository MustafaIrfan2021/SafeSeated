using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SafeSeatedBackend.Data;
using SafeSeatedBackend.Middleware;
using SafeSeatedBackend.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
});

var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<SafeSeatedDbContext>(options => options.UseSqlServer(connectionString));

var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = jwtSettings["SecretKey"] ?? throw new InvalidOperationException("JWT SecretKey not configured.");
if (Encoding.UTF8.GetByteCount(secretKey) < 32)
    throw new InvalidOperationException("JWT SecretKey must be at least 32 bytes. Set Jwt:SecretKey in user secrets or environment variables.");

var issuer = jwtSettings["Issuer"] ?? throw new InvalidOperationException("JWT Issuer not configured.");
var audience = jwtSettings["Audience"] ?? throw new InvalidOperationException("JWT Audience not configured.");
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = issuer,
            ValidAudience = audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey))
        };
    });

builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SafeSeated API",
        Version = "v1",
        Description = "REST API for the SafeSeated mobile carpooling app"
    });
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "JWT Authentication",
        Description = "Enter JWT Bearer token",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT"
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        { new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            Array.Empty<string>() }
    });
});

builder.Services.AddCors(options => options.AddPolicy("AllowAll", policy =>
    policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));
builder.Services.AddHealthChecks();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "SafeSeated API v1");
        options.RoutePrefix = "swagger";
    });
}

app.UseGlobalException();
app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseStaticFiles();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHealthChecks("/health");

if (app.Configuration.GetValue<bool>("Database:ApplyMigrationsOnStartup"))
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<SafeSeatedDbContext>();
    await db.Database.MigrateAsync();

    var adminEmail = app.Configuration["Admin:Email"]?.Trim().ToLowerInvariant();
    var adminPassword = app.Configuration["Admin:Password"];
    if (string.IsNullOrWhiteSpace(adminEmail) || string.IsNullOrWhiteSpace(adminPassword)
        || adminPassword.Length < 8 || Encoding.UTF8.GetByteCount(adminPassword) > 72)
    {
        throw new InvalidOperationException(
            "Set Admin:Email and an Admin:Password between 8 and 72 UTF-8 bytes before enabling startup initialization.");
    }

    var admin = await db.Users.FirstOrDefaultAsync(user => user.Email == adminEmail);
    if (admin != null && admin.Role != UserRole.Admin)
        throw new InvalidOperationException("The configured admin email is already used by a non-admin account.");

    if (admin == null)
    {
        db.Users.Add(new User
        {
            FullName = "SafeSeated Admin",
            Email = adminEmail,
            Phone = "03000000000",
            Cnic = "0000000000000",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(adminPassword),
            Role = UserRole.Admin,
            Status = UserStatus.Verified
        });
        await db.SaveChangesAsync();
    }
}

app.Run();
