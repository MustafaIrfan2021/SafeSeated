IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE TABLE [Users] (
        [Id] uniqueidentifier NOT NULL,
        [Role] nvarchar(50) NOT NULL,
        [Name] nvarchar(100) NOT NULL,
        [Phone] nvarchar(20) NOT NULL,
        [Email] nvarchar(100) NOT NULL,
        [PasswordHash] nvarchar(max) NOT NULL,
        [Cnic] nvarchar(21) NOT NULL,
        [VerificationStatus] nvarchar(50) NOT NULL,
        [RejectionReason] nvarchar(500) NULL,
        [LastLoginAt] datetime2 NULL,
        [CreatedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE TABLE [DriverProfiles] (
        [Id] uniqueidentifier NOT NULL,
        [UserId] uniqueidentifier NOT NULL,
        [City] nvarchar(50) NOT NULL,
        [LicenceNumber] nvarchar(20) NOT NULL,
        [VehicleModel] nvarchar(100) NOT NULL,
        [VehicleMake] nvarchar(50) NOT NULL,
        [VehicleColour] nvarchar(30) NOT NULL,
        [PlateNumber] nvarchar(15) NOT NULL,
        [VehicleYear] int NOT NULL,
        [SeatsForPassengers] int NOT NULL,
        [SeatCapacity] int NOT NULL DEFAULT 1,
        [VehicleRegistrationNumber] nvarchar(50) NOT NULL,
        [IsOnline] bit NOT NULL DEFAULT CAST(1 AS bit),
        [AverageRating] float NULL,
        [CreatedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_DriverProfiles] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_DriverProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE TABLE [PassengerProfiles] (
        [Id] uniqueidentifier NOT NULL,
        [UserId] uniqueidentifier NOT NULL,
        [University] nvarchar(100) NOT NULL,
        [StudentId] nvarchar(20) NOT NULL,
        [Program] nvarchar(100) NOT NULL,
        [Cnic] nvarchar(13) NOT NULL,
        [Semester] nvarchar(30) NOT NULL,
        [EmergencyContactName] nvarchar(100) NOT NULL,
        [EmergencyContactPhone] nvarchar(20) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_PassengerProfiles] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_PassengerProfiles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE TABLE [RideRequests] (
        [Id] uniqueidentifier NOT NULL,
        [PassengerId] uniqueidentifier NOT NULL,
        [Pickup] nvarchar(100) NOT NULL,
        [Destination] nvarchar(100) NOT NULL,
        [RequestedTime] datetime2 NOT NULL,
        [Seats] int NOT NULL,
        [Status] nvarchar(50) NOT NULL,
        [AcceptedDriverId] uniqueidentifier NULL,
        [CreatedRideId] uniqueidentifier NULL,
        [RowVersion] bigint NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_RideRequests] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_RideRequests_Users_AcceptedDriverId] FOREIGN KEY ([AcceptedDriverId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_RideRequests_Users_PassengerId] FOREIGN KEY ([PassengerId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE TABLE [VerificationDocuments] (
        [Id] uniqueidentifier NOT NULL,
        [UserId] uniqueidentifier NOT NULL,
        [DocumentType] nvarchar(50) NOT NULL,
        [FilePath] nvarchar(500) NOT NULL,
        [ContentType] nvarchar(100) NOT NULL,
        [OriginalFileName] nvarchar(255) NOT NULL,
        [Status] nvarchar(50) NOT NULL,
        [ReviewedByAdminId] uniqueidentifier NULL,
        [ReviewedAt] datetime2 NULL,
        [RejectionReason] nvarchar(500) NULL,
        [UploadedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_VerificationDocuments] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_VerificationDocuments_Users_ReviewedByAdminId] FOREIGN KEY ([ReviewedByAdminId]) REFERENCES [Users] ([Id]),
        CONSTRAINT [FK_VerificationDocuments_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE TABLE [Rides] (
        [Id] uniqueidentifier NOT NULL,
        [DriverId] uniqueidentifier NOT NULL,
        [Pickup] nvarchar(100) NOT NULL,
        [Destination] nvarchar(100) NOT NULL,
        [Notes] nvarchar(500) NULL,
        [DepartureTime] datetime2 NOT NULL,
        [FarePerSeat] decimal(10,2) NOT NULL,
        [TotalSeats] int NOT NULL,
        [Status] nvarchar(50) NOT NULL,
        [SourceRideRequestId] uniqueidentifier NULL,
        [RowVersion] bigint NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_Rides] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Rides_RideRequests_SourceRideRequestId] FOREIGN KEY ([SourceRideRequestId]) REFERENCES [RideRequests] ([Id]) ON DELETE SET NULL,
        CONSTRAINT [FK_Rides_Users_DriverId] FOREIGN KEY ([DriverId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE TABLE [Bookings] (
        [Id] uniqueidentifier NOT NULL,
        [RideId] uniqueidentifier NOT NULL,
        [PassengerId] uniqueidentifier NOT NULL,
        [Seats] int NOT NULL,
        [FareTotal] decimal(10,2) NOT NULL,
        [PickupTime] datetime2 NOT NULL,
        [Status] nvarchar(50) NOT NULL,
        [TravelDate] datetime2 NOT NULL,
        [UpdatedAt] datetime2 NOT NULL,
        [Rating] int NULL,
        [Review] nvarchar(500) NULL,
        [RatedAt] datetime2 NULL,
        [CreatedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_Bookings] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Bookings_Rides_RideId] FOREIGN KEY ([RideId]) REFERENCES [Rides] ([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_Bookings_Users_PassengerId] FOREIGN KEY ([PassengerId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE TABLE [Complaints] (
        [Id] uniqueidentifier NOT NULL,
        [ReporterId] uniqueidentifier NOT NULL,
        [RideId] uniqueidentifier NULL,
        [DriverId] uniqueidentifier NULL,
        [Description] nvarchar(1000) NOT NULL,
        [Status] nvarchar(50) NOT NULL,
        [AdminNotes] nvarchar(1000) NULL,
        [CreatedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_Complaints] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Complaints_Rides_RideId] FOREIGN KEY ([RideId]) REFERENCES [Rides] ([Id]),
        CONSTRAINT [FK_Complaints_Users_DriverId] FOREIGN KEY ([DriverId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Complaints_Users_ReporterId] FOREIGN KEY ([ReporterId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Bookings_PassengerId] ON [Bookings] ([PassengerId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_Bookings_RideId_PassengerId] ON [Bookings] ([RideId], [PassengerId]) WHERE [Status] IN (''Pending'', ''Accepted'', ''Active'')');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Bookings_Status] ON [Bookings] ([Status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Complaints_DriverId] ON [Complaints] ([DriverId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Complaints_ReporterId] ON [Complaints] ([ReporterId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Complaints_RideId] ON [Complaints] ([RideId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Complaints_Status] ON [Complaints] ([Status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE UNIQUE INDEX [IX_DriverProfiles_PlateNumber] ON [DriverProfiles] ([PlateNumber]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE UNIQUE INDEX [IX_DriverProfiles_UserId] ON [DriverProfiles] ([UserId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE UNIQUE INDEX [IX_PassengerProfiles_UserId] ON [PassengerProfiles] ([UserId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_RideRequests_AcceptedDriverId] ON [RideRequests] ([AcceptedDriverId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_RideRequests_PassengerId] ON [RideRequests] ([PassengerId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_RideRequests_RequestedTime] ON [RideRequests] ([RequestedTime]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_RideRequests_Status] ON [RideRequests] ([Status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Rides_DepartureTime] ON [Rides] ([DepartureTime]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Rides_DriverId] ON [Rides] ([DriverId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_Rides_SourceRideRequestId] ON [Rides] ([SourceRideRequestId]) WHERE [SourceRideRequestId] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_Rides_Status] ON [Rides] ([Status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Users_Cnic] ON [Users] ([Cnic]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Users_Email] ON [Users] ([Email]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Users_Phone] ON [Users] ([Phone]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_VerificationDocuments_ReviewedByAdminId] ON [VerificationDocuments] ([ReviewedByAdminId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    CREATE INDEX [IX_VerificationDocuments_UserId_DocumentType] ON [VerificationDocuments] ([UserId], [DocumentType]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117163053_InitialSafeSeatedSchema'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117163053_InitialSafeSeatedSchema', N'10.0.15');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117164751_AddDriverCnicToDriverProfiles'
)
BEGIN
    ALTER TABLE [DriverProfiles] ADD [Cnic] nvarchar(13) NOT NULL DEFAULT N'';
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117164751_AddDriverCnicToDriverProfiles'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117164751_AddDriverCnicToDriverProfiles', N'10.0.15');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117165137_AlignAuthenticationColumnLengths'
)
BEGIN
    DECLARE @var nvarchar(max);
    SELECT @var = QUOTENAME([d].[name])
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[DriverProfiles]') AND [c].[name] = N'LicenceNumber');
    IF @var IS NOT NULL EXEC(N'ALTER TABLE [DriverProfiles] DROP CONSTRAINT ' + @var + ';');
    ALTER TABLE [DriverProfiles] ALTER COLUMN [LicenceNumber] nvarchar(50) NOT NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117165137_AlignAuthenticationColumnLengths'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117165137_AlignAuthenticationColumnLengths', N'10.0.15');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117165631_TightenUserIdentityColumnLengths'
)
BEGIN
    DROP INDEX [IX_Users_Phone] ON [Users];
    DECLARE @var1 nvarchar(max);
    SELECT @var1 = QUOTENAME([d].[name])
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Users]') AND [c].[name] = N'Phone');
    IF @var1 IS NOT NULL EXEC(N'ALTER TABLE [Users] DROP CONSTRAINT ' + @var1 + ';');
    ALTER TABLE [Users] ALTER COLUMN [Phone] nvarchar(11) NOT NULL;
    CREATE UNIQUE INDEX [IX_Users_Phone] ON [Users] ([Phone]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117165631_TightenUserIdentityColumnLengths'
)
BEGIN
    DROP INDEX [IX_Users_Cnic] ON [Users];
    DECLARE @var2 nvarchar(max);
    SELECT @var2 = QUOTENAME([d].[name])
    FROM [sys].[default_constraints] [d]
    INNER JOIN [sys].[columns] [c] ON [d].[parent_column_id] = [c].[column_id] AND [d].[parent_object_id] = [c].[object_id]
    WHERE ([d].[parent_object_id] = OBJECT_ID(N'[Users]') AND [c].[name] = N'Cnic');
    IF @var2 IS NOT NULL EXEC(N'ALTER TABLE [Users] DROP CONSTRAINT ' + @var2 + ';');
    ALTER TABLE [Users] ALTER COLUMN [Cnic] nvarchar(13) NOT NULL;
    CREATE UNIQUE INDEX [IX_Users_Cnic] ON [Users] ([Cnic]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117165631_TightenUserIdentityColumnLengths'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117165631_TightenUserIdentityColumnLengths', N'10.0.15');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261117170157_RemoveUnusedRefreshTokenModel'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261117170157_RemoveUnusedRefreshTokenModel', N'10.0.15');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261122160351_AddEmergencyAlerts'
)
BEGIN
    ALTER TABLE [DriverProfiles] ADD [EmergencyContactName] nvarchar(100) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261122160351_AddEmergencyAlerts'
)
BEGIN
    ALTER TABLE [DriverProfiles] ADD [EmergencyContactPhone] nvarchar(11) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261122160351_AddEmergencyAlerts'
)
BEGIN
    CREATE TABLE [EmergencyAlerts] (
        [Id] uniqueidentifier NOT NULL,
        [UserId] uniqueidentifier NOT NULL,
        [ReporterRole] nvarchar(50) NOT NULL,
        [ClientRequestId] nvarchar(64) NOT NULL,
        [Latitude] float NULL,
        [Longitude] float NULL,
        [RideId] uniqueidentifier NULL,
        [Status] nvarchar(20) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        [IsDeleted] bit NOT NULL,
        CONSTRAINT [PK_EmergencyAlerts] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_EmergencyAlerts_Rides_RideId] FOREIGN KEY ([RideId]) REFERENCES [Rides] ([Id]) ON DELETE SET NULL,
        CONSTRAINT [FK_EmergencyAlerts_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261122160351_AddEmergencyAlerts'
)
BEGIN
    CREATE INDEX [IX_EmergencyAlerts_CreatedAt] ON [EmergencyAlerts] ([CreatedAt]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261122160351_AddEmergencyAlerts'
)
BEGIN
    CREATE INDEX [IX_EmergencyAlerts_RideId] ON [EmergencyAlerts] ([RideId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261122160351_AddEmergencyAlerts'
)
BEGIN
    CREATE UNIQUE INDEX [IX_EmergencyAlerts_UserId_ClientRequestId] ON [EmergencyAlerts] ([UserId], [ClientRequestId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261122160351_AddEmergencyAlerts'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261122160351_AddEmergencyAlerts', N'10.0.15');
END;

COMMIT;
GO

