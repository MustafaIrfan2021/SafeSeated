import 'user_role.dart';
import 'verification_status.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final UserRole role;
  final VerificationStatus status;

  // Passenger specific fields
  final String? cnic;
  final String? university;
  final String? studentId;
  final String? programSemester;

  // Emergency contact shared by both account roles
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  // Driver Specific fields
  final String? city;
  final String? licenseNumber;
  final String? vehicleRegistration;
  final String? vehicleMake;
  final String? vehiclePlate;
  final String? vehicleColor;
  final String? vehicleYear;
  final int seatsTotal;
  final bool isOffline;

  // Documents
  final List<String> documents;
  final double rating;
  final int reviewsCount;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.status = VerificationStatus.pending,
    this.cnic,
    this.university,
    this.studentId,
    this.programSemester,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.city,
    this.licenseNumber,
    this.vehicleRegistration,
    this.vehicleMake,
    this.vehiclePlate,
    this.vehicleColor,
    this.vehicleYear,
    this.seatsTotal = 3,
    this.isOffline = false,
    this.documents = const [],
    this.rating = 5.0,
    this.reviewsCount = 0,
  });

  bool get isApproved => status == VerificationStatus.approved;
  bool get isPassenger => role == UserRole.passenger;
  bool get isDriver => role == UserRole.driver;
  bool get isAdmin => role == UserRole.admin;

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? password,
    UserRole? role,
    VerificationStatus? status,
    String? cnic,
    String? university,
    String? studentId,
    String? programSemester,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? city,
    String? licenseNumber,
    String? vehicleRegistration,
    String? vehicleMake,
    String? vehiclePlate,
    String? vehicleColor,
    String? vehicleYear,
    int? seatsTotal,
    bool? isOffline,
    List<String>? documents,
    double? rating,
    int? reviewsCount,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      role: role ?? this.role,
      status: status ?? this.status,
      cnic: cnic ?? this.cnic,
      university: university ?? this.university,
      studentId: studentId ?? this.studentId,
      programSemester: programSemester ?? this.programSemester,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      city: city ?? this.city,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      isOffline: isOffline ?? this.isOffline,
      documents: documents ?? this.documents,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
    );
  }
}
