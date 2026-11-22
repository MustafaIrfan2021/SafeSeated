import '../models/user.dart';
import '../models/user_role.dart';
import '../models/notification_item.dart';

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login({
    required String email,
    required String password,
    required UserRole role,
  });
  Future<void> logout();
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
  });
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
  });
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<User> updatePassengerProfile({
    required String name,
    required String phone,
    required String university,
    required String studentId,
    required String programSemester,
    required String emergencyContactName,
    required String emergencyContactPhone,
  });
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
  });
  Future<List<NotificationItem>> getNotifications(String userEmail);
  Future<void> markNotificationsRead(String userEmail);
  Future<void> simulateApproval(String userEmail);
  Future<void> resetDemoData();
}
