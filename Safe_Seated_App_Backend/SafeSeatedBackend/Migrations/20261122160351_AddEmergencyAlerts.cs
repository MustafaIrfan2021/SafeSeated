using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SafeSeatedBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddEmergencyAlerts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "EmergencyContactName",
                table: "DriverProfiles",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EmergencyContactPhone",
                table: "DriverProfiles",
                type: "nvarchar(11)",
                maxLength: 11,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "EmergencyAlerts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    UserId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ReporterRole = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: false),
                    ClientRequestId = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    Latitude = table.Column<double>(type: "float", nullable: true),
                    Longitude = table.Column<double>(type: "float", nullable: true),
                    RideId = table.Column<Guid>(type: "uniqueidentifier", nullable: true),
                    Status = table.Column<string>(type: "nvarchar(20)", maxLength: 20, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EmergencyAlerts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EmergencyAlerts_Rides_RideId",
                        column: x => x.RideId,
                        principalTable: "Rides",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_EmergencyAlerts_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_EmergencyAlerts_CreatedAt",
                table: "EmergencyAlerts",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_EmergencyAlerts_RideId",
                table: "EmergencyAlerts",
                column: "RideId");

            migrationBuilder.CreateIndex(
                name: "IX_EmergencyAlerts_UserId_ClientRequestId",
                table: "EmergencyAlerts",
                columns: new[] { "UserId", "ClientRequestId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "EmergencyAlerts");

            migrationBuilder.DropColumn(
                name: "EmergencyContactName",
                table: "DriverProfiles");

            migrationBuilder.DropColumn(
                name: "EmergencyContactPhone",
                table: "DriverProfiles");
        }
    }
}
