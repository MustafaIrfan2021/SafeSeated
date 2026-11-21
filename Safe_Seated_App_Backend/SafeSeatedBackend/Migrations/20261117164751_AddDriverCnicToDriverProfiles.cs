using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace SafeSeatedBackend.Migrations
{
    /// <inheritdoc />
    public partial class AddDriverCnicToDriverProfiles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Cnic",
                table: "DriverProfiles",
                type: "nvarchar(13)",
                maxLength: 13,
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Cnic",
                table: "DriverProfiles");
        }
    }
}
