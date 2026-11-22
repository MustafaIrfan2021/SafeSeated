import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/jwt_expiration.dart';
import '../../../core/network/token_storage.dart';
import '../domain/models/notification_item.dart';
import '../domain/models/user.dart';
import '../domain/models/user_role.dart';
import '../domain/models/verification_status.dart';
import '../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _api = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  @override
  Future<User?> getCurrentUser() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      if (!JwtExpiration.read(token).isAfter(DateTime.now().toUtc())) {
        await _api.clearToken();
        return null;
      }
      return await _fetchProfile();
    } on FormatException {
      await _api.clearToken();
      return null;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _api.clearToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<User> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final response = await _api.postJson('/auth/login', {
      'email': email.trim(),
      'password': password,
    }, authenticated: false);

    final token = response['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException(
        message: 'The login response did not contain a token.',
      );
    }
    await _tokenStorage.writeToken(token);

    final user = await _fetchProfile();
    if (user.role != role) {
      await _api.clearToken();
      throw ApiException(
        message: 'This account is not a ${role.label.toLowerCase()} account.',
      );
    }
    return user;
  }

  @override
  Future<void> logout() => _api.clearToken();

  @override
  Future<User> registerPassenger({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String cnic,
    required String university,
    required String studentId,
    required String programSemester,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required List<String> documents,
  }) async {
    await _api.postJson('/auth/register/passenger', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': _normalizePakistanPhone(phone),
      'cnic': cnic.replaceAll(RegExp(r'\D'), ''),
      'password': password,
      'university': university.trim(),
      'studentId': studentId.trim(),
      'program': programSemester.trim(),
      'semester': _semesterFromProgram(programSemester),
      'emergencyContactName': emergencyContactName.trim(),
      'emergencyContactPhone': _normalizePakistanPhone(emergencyContactPhone),
    }, authenticated: false);

    return login(email: email, password: password, role: UserRole.passenger);
  }

  @override
  Future<User> registerDriver({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String cnic,
    required String city,
    required String licenseNumber,
    required String vehicleMake,
    required String vehicleColor,
    required String vehiclePlate,
    required String vehicleYear,
    required int seatsTotal,
    required String vehicleRegistration,
    required List<String> documents,
  }) async {
    final year = int.tryParse(vehicleYear);
    if (year == null) {
      throw const ApiException(message: 'Enter a valid vehicle model year.');
    }

    await _api.postJson('/auth/register/driver', {
      'name': name.trim(),
      'email': email.trim(),
      'phone': _normalizePakistanPhone(phone),
      'cnic': cnic.replaceAll(RegExp(r'\D'), ''),
      'password': password,
      'city': city.trim(),
      'licenceNumber': licenseNumber.trim(),
      'vehicleMake': vehicleMake.trim(),
      'vehicleModel': vehicleMake.trim(),
      'vehicleColour': vehicleColor.trim(),
      'plateNumber': vehiclePlate.trim(),
      'vehicleYear': year,
      'seatCapacity': seatsTotal,
    }, authenticated: false);

    return login(email: email, password: password, role: UserRole.driver);
  }

  Future<User> _fetchProfile() async {
    final data = await _api.getJson('/me');
    final passenger = data['passengerProfile'];
    final driver = data['driverProfile'];

    final role = _roleFromCode(data['role']?.toString());
    final status = _statusFromCode(data['verificationStatus']?.toString());

    return User(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phone']?.toString() ?? '',
      password: '',
      cnic: data['cnic']?.toString(),
      role: role,
      status: status,
      university: passenger is Map ? passenger['university']?.toString() : null,
      studentId: passenger is Map ? passenger['studentId']?.toString() : null,
      programSemester: passenger is Map
          ? passenger['program']?.toString()
          : null,
      emergencyContactName: passenger is Map
          ? passenger['emergencyContactName']?.toString()
          : driver is Map
          ? driver['emergencyContactName']?.toString()
          : null,
      emergencyContactPhone: passenger is Map
          ? passenger['emergencyContactPhone']?.toString()
          : driver is Map
          ? driver['emergencyContactPhone']?.toString()
          : null,
      city: driver is Map ? driver['city']?.toString() : null,
      licenseNumber: driver is Map ? driver['licenceNumber']?.toString() : null,
      vehicleMake: driver is Map ? driver['vehicleMake']?.toString() : null,
      vehiclePlate: driver is Map ? driver['plateNumber']?.toString() : null,
      vehicleRegistration: driver is Map
          ? driver['plateNumber']?.toString()
          : null,
      vehicleColor: driver is Map ? driver['vehicleColour']?.toString() : null,
      vehicleYear: driver is Map ? driver['vehicleYear']?.toString() : null,
      seatsTotal: driver is Map
          ? (driver['seatCapacity'] is num
                ? (driver['seatCapacity'] as num).toInt()
                : 3)
          : 3,
      isOffline: driver is Map
          ? driver['isOnline'] is bool
                ? !(driver['isOnline'] as bool)
                : false
          : false,
    );
  }

  static String _semesterFromProgram(String programSemester) {
    final parts = programSemester.split('-');
    return parts.length > 1
        ? parts.sublist(1).join('-').trim()
        : programSemester;
  }

  static String _normalizePakistanPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92') && digits.length == 12) {
      return '0${digits.substring(2)}';
    }
    if (digits.startsWith('00923')) {
      return '0${digits.substring(5)}';
    }
    return digits;
  }

  static UserRole _roleFromCode(String? role) {
    switch (role?.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.passenger;
    }
  }

  static VerificationStatus _statusFromCode(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    throw const ApiException(
      message: 'Password changes are not available through the backend API.',
    );
  }

  @override
  Future<User> updatePassengerProfile({
    required String name,
    required String phone,
    required String university,
    required String studentId,
    required String programSemester,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    await _api.patchJson('/me', {
      'name': name.trim(),
      'phone': _normalizePakistanPhone(phone),
      'university': university.trim(),
      'studentId': studentId.trim(),
      'program': programSemester.trim(),
      'emergencyContactName': emergencyContactName.trim(),
      'emergencyContactPhone': _normalizePakistanPhone(emergencyContactPhone),
    });
    return _fetchProfile();
  }

  @override
  Future<User> updateDriverProfile({
    required String name,
    required String phone,
    required String city,
    required String licenseNumber,
    required String vehicleRegistration,
    required String vehicleMake,
    required String vehicleColor,
    required String vehiclePlate,
    required String vehicleYear,
    required int seatsTotal,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    await _api.patchJson('/me', {
      'name': name.trim(),
      'phone': _normalizePakistanPhone(phone),
      'city': city.trim(),
      'licenceNumber': licenseNumber.trim(),
      'vehicleMake': vehicleMake.trim(),
      'vehicleColour': vehicleColor.trim(),
      'plateNumber': vehiclePlate.trim(),
      'vehicleYear': int.tryParse(vehicleYear),
      'seatCapacity': seatsTotal,
      'emergencyContactName': emergencyContactName.trim(),
      'emergencyContactPhone': emergencyContactPhone.trim().isEmpty
          ? ''
          : _normalizePakistanPhone(emergencyContactPhone),
    });
    return _fetchProfile();
  }

  @override
  Future<List<NotificationItem>> getNotifications(String userEmail) async => [];

  @override
  Future<void> markNotificationsRead(String userEmail) async {}

  @override
  Future<void> simulateApproval(String userEmail) async {
    throw const ApiException(
      message: 'Verification must be completed by an Admin in the backend.',
    );
  }

  @override
  Future<void> resetDemoData() async {}
}
