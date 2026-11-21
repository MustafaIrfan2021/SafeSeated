import '../domain/models/user.dart';
import '../domain/models/user_role.dart';
import '../domain/models/verification_status.dart';
import '../domain/models/notification_item.dart';
import '../domain/repositories/auth_repository.dart';
import '../../../core/validation/form_validators.dart';

class MockAuthRepository implements AuthRepository {
  static final User _initialPassenger = User(
    id: 'usr_p1',
    name: 'Ayesha Khan',
    email: 'ayesha@smiu.edu.pk',
    phone: '0312-5550142',
    password: '1234',
    role: UserRole.passenger,
    status: VerificationStatus.approved,
    cnic: '42201-1234567-8',
    university: 'SMIU (Sindh Madressatul Islam University)',
    studentId: 'CSC-22F-042',
    programSemester: 'BSCS - 5th Semester',
    emergencyContactName: 'Fatima Khan (Mother)',
    emergencyContactPhone: '0300-1234567',
    documents: const [
      'CNIC (front & back)',
      'University ID card',
      'Selfie photo',
    ],
    rating: 5.0,
    reviewsCount: 3,
  );

  static final User _initialDriver1 = User(
    id: 'usr_d1',
    name: 'Sana Malik',
    email: 'sana@safeseated.pk',
    phone: '0333-4445566',
    password: '1234',
    role: UserRole.driver,
    status: VerificationStatus.approved,
    cnic: '42101-9876543-2',
    city: 'Karachi',
    licenseNumber: 'KHI-DL-88210',
    vehicleRegistration: 'BCA-412',
    vehicleMake: 'Suzuki Alto VXR',
    vehiclePlate: 'BCA-412',
    vehicleColor: 'Silver',
    vehicleYear: '2022',
    seatsTotal: 3,
    documents: const [
      'CNIC (front & back)',
      'Driving licence',
      'Vehicle registration book',
      'Vehicle photo',
      'Selfie photo',
    ],
    rating: 4.9,
    reviewsCount: 14,
  );

  static final User _initialDriver2 = User(
    id: 'usr_d2',
    name: 'Hina Raza',
    email: 'hina@safeseated.pk',
    phone: '0345-9988776',
    password: '1234',
    role: UserRole.driver,
    status: VerificationStatus.approved,
    cnic: '42301-4433221-0',
    city: 'Karachi',
    licenseNumber: 'KHI-DL-99124',
    vehicleRegistration: 'KHI-789',
    vehicleMake: 'Honda City 1.2',
    vehiclePlate: 'KHI-789',
    vehicleColor: 'White',
    vehicleYear: '2021',
    seatsTotal: 3,
    documents: const [
      'CNIC (front & back)',
      'Driving licence',
      'Vehicle registration book',
      'Vehicle photo',
      'Selfie photo',
    ],
    rating: 4.8,
    reviewsCount: 9,
  );

  final List<User> _users = [
    _initialPassenger,
    _initialDriver1,
    _initialDriver2,
  ];

  User? _currentUser;

  final List<NotificationItem> _notifications = [
    const NotificationItem(
      id: 'notif_1',
      toEmail: 'ayesha@smiu.edu.pk',
      title: 'Booking accepted',
      body: 'Hina Raza accepted your Clifton ride.',
      time: '20 min ago',
      isRead: false,
    ),
    const NotificationItem(
      id: 'notif_2',
      toEmail: 'ayesha@smiu.edu.pk',
      title: 'Ride reminder',
      body: 'Your ride tomorrow departs at 8:30 AM from Clifton.',
      time: '2 hours ago',
      isRead: false,
    ),
    const NotificationItem(
      id: 'notif_3',
      toEmail: 'ayesha@smiu.edu.pk',
      title: 'Welcome to SafeSeated',
      body: 'Your university student verification was approved.',
      time: 'Yesterday',
      isRead: true,
    ),
  ];

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<User> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.trim().toLowerCase();
    final index = _users.indexWhere(
      (u) =>
          u.email.toLowerCase() == cleanEmail &&
          u.password == password &&
          u.role == role,
    );

    if (index == -1) {
      throw Exception('Incorrect username or password.');
    }

    final user = _users[index];
    if (user.status == VerificationStatus.suspended) {
      throw Exception(
        'This account has been suspended. Please contact SafeSeated support.',
      );
    }

    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }

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
    await Future.delayed(const Duration(milliseconds: 400));
    const requiredDocuments = {
      'CNIC (front & back)',
      'University ID card',
      'Selfie photo',
    };
    if (name.trim().isEmpty ||
        !FormValidators.isValidPakistanPhone(phone) ||
        !FormValidators.isValidEmail(email) ||
        password.trim().length < 4 ||
        !FormValidators.isValidCnic(cnic) ||
        university.trim().isEmpty ||
        studentId.trim().isEmpty ||
        programSemester.trim().isEmpty ||
        emergencyContactName.trim().isEmpty ||
        !FormValidators.isValidPakistanPhone(emergencyContactPhone) ||
        !documents.toSet().containsAll(requiredDocuments)) {
      throw ArgumentError(
        'Enter valid passenger details and select all required documents.',
      );
    }
    final cleanEmail = email.trim().toLowerCase();
    if (_users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      throw Exception('This email is already registered. Please log in.');
    }

    final newUser = User(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      password: password,
      role: UserRole.passenger,
      status: VerificationStatus.pending,
      cnic: cnic.trim(),
      university: university.trim(),
      studentId: studentId.trim(),
      programSemester: programSemester.trim(),
      emergencyContactName: emergencyContactName.trim(),
      emergencyContactPhone: emergencyContactPhone.trim(),
      documents: List.unmodifiable(documents),
    );

    _users.add(newUser);
    _currentUser = newUser;
    return newUser;
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
    await Future.delayed(const Duration(milliseconds: 400));
    const requiredDocuments = {
      'CNIC (front & back)',
      'Driving licence',
      'Vehicle registration book',
      'Vehicle photo',
      'Selfie photo',
    };
    if (name.trim().isEmpty ||
        !FormValidators.isValidPakistanPhone(phone) ||
        !FormValidators.isValidEmail(email) ||
        password.trim().length < 4 ||
        !FormValidators.isValidCnic(cnic) ||
        city.trim().isEmpty ||
        licenseNumber.trim().isEmpty ||
        vehicleMake.trim().isEmpty ||
        vehicleColor.trim().isEmpty ||
        vehiclePlate.trim().isEmpty ||
        !FormValidators.isValidVehicleYear(vehicleYear) ||
        vehicleRegistration.trim().isEmpty ||
        !documents.toSet().containsAll(requiredDocuments)) {
      throw ArgumentError(
        'Required driver, vehicle and document details are missing.',
      );
    }
    if (seatsTotal < 1 || seatsTotal > 4) {
      throw ArgumentError.value(
        seatsTotal,
        'seatsTotal',
        'Must be between 1 and 4.',
      );
    }
    final cleanEmail = email.trim().toLowerCase();
    if (_users.any((user) => user.email.toLowerCase() == cleanEmail)) {
      throw StateError('This email is already registered. Please log in.');
    }

    final user = User(
      id: 'usr_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      phone: phone.trim(),
      password: password,
      role: UserRole.driver,
      status: VerificationStatus.pending,
      cnic: cnic.trim(),
      city: city.trim(),
      licenseNumber: licenseNumber.trim(),
      vehicleRegistration: vehicleRegistration.trim(),
      vehicleMake: vehicleMake.trim(),
      vehiclePlate: vehiclePlate.trim(),
      vehicleColor: vehicleColor.trim(),
      vehicleYear: vehicleYear.trim(),
      seatsTotal: seatsTotal,
      documents: List.unmodifiable(documents),
    );
    _users.add(user);
    _currentUser = user;
    return user;
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_currentUser == null) throw Exception('No user logged in.');
    if (_currentUser!.password != currentPassword) {
      throw Exception('Current password does not match.');
    }
    if (newPassword.length < 4) {
      throw Exception('New password must be at least 4 characters.');
    }

    final updated = _currentUser!.copyWith(password: newPassword);
    final idx = _users.indexWhere((u) => u.email == _currentUser!.email);
    if (idx != -1) _users[idx] = updated;
    _currentUser = updated;
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
    await Future.delayed(const Duration(milliseconds: 200));
    final current = _currentUser;
    if (current == null || !current.isPassenger) {
      throw StateError(
        'A passenger session is required to update this profile.',
      );
    }

    var updated = current.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      university: university.trim(),
      studentId: studentId.trim(),
      programSemester: programSemester.trim(),
      emergencyContactName: emergencyContactName.trim(),
      emergencyContactPhone: emergencyContactPhone.trim(),
    );
    final index = _users.indexWhere((user) => user.id == current.id);
    if (index == -1) {
      throw StateError('The current passenger profile was not found.');
    }
    final identityDetailsChanged =
        current.university != updated.university ||
        current.studentId != updated.studentId ||
        current.programSemester != updated.programSemester;
    if (identityDetailsChanged) {
      updated = updated.copyWith(status: VerificationStatus.pending);
    }
    _users[index] = updated;
    _currentUser = updated;
    return updated;
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final current = _currentUser;
    if (current == null || !current.isDriver) {
      throw StateError('A driver session is required to update this profile.');
    }
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        city.trim().isEmpty ||
        licenseNumber.trim().isEmpty ||
        vehicleRegistration.trim().isEmpty ||
        vehicleMake.trim().isEmpty ||
        vehicleColor.trim().isEmpty ||
        vehiclePlate.trim().isEmpty ||
        vehicleYear.trim().isEmpty) {
      throw ArgumentError(
        'All driver and vehicle profile fields are required.',
      );
    }
    if (seatsTotal < 1 || seatsTotal > 4) {
      throw ArgumentError.value(
        seatsTotal,
        'seatsTotal',
        'Must be between 1 and 4.',
      );
    }
    final updated = current.copyWith(
      name: name.trim(),
      phone: phone.trim(),
      city: city.trim(),
      licenseNumber: licenseNumber.trim(),
      vehicleRegistration: vehicleRegistration.trim(),
      vehicleMake: vehicleMake.trim(),
      vehicleColor: vehicleColor.trim(),
      vehiclePlate: vehiclePlate.trim(),
      vehicleYear: vehicleYear.trim(),
      seatsTotal: seatsTotal,
    );
    final verificationDetailsChanged =
        current.licenseNumber != updated.licenseNumber ||
        current.vehicleRegistration != updated.vehicleRegistration ||
        current.vehicleMake != updated.vehicleMake ||
        current.vehicleColor != updated.vehicleColor ||
        current.vehiclePlate != updated.vehiclePlate ||
        current.vehicleYear != updated.vehicleYear;
    final profile = verificationDetailsChanged
        ? updated.copyWith(status: VerificationStatus.pending)
        : updated;
    final index = _users.indexWhere((user) => user.id == current.id);
    if (index == -1) {
      throw StateError('The current driver profile was not found.');
    }
    _users[index] = profile;
    _currentUser = profile;
    return profile;
  }

  @override
  Future<List<NotificationItem>> getNotifications(String userEmail) async {
    return _notifications
        .where((n) => n.toEmail.toLowerCase() == userEmail.toLowerCase())
        .toList();
  }

  @override
  Future<void> markNotificationsRead(String userEmail) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].toEmail.toLowerCase() == userEmail.toLowerCase()) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  @override
  Future<void> simulateApproval(String userEmail) async {
    final idx = _users.indexWhere(
      (u) => u.email.toLowerCase() == userEmail.toLowerCase(),
    );
    if (idx != -1) {
      final updated = _users[idx].copyWith(status: VerificationStatus.approved);
      _users[idx] = updated;
      if (_currentUser?.email.toLowerCase() == userEmail.toLowerCase()) {
        _currentUser = updated;
      }
      _notifications.insert(
        0,
        NotificationItem(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          toEmail: userEmail,
          title: 'Account Verified',
          body:
              'Demo approval was simulated. This sample account can now open the verified account features.',
          time: 'Just now',
          isRead: false,
        ),
      );
    }
  }

  @override
  Future<void> resetDemoData() async {
    _users.clear();
    _users.addAll([_initialPassenger, _initialDriver1, _initialDriver2]);
    _currentUser = null;
  }
}
