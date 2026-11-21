import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/models/user.dart';
import '../../features/auth/domain/models/user_role.dart';
import '../../features/auth/domain/models/verification_status.dart';
import '../../features/auth/domain/models/notification_item.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/api_auth_repository.dart';
import '../../core/network/api_client.dart';
import '../../core/network/token_storage.dart';
import '../../features/passenger/domain/models/ride.dart';
import '../../features/passenger/domain/models/booking.dart';
import '../../features/passenger/domain/models/ride_request.dart';
import '../../features/passenger/domain/models/chat_message.dart';
import '../../features/passenger/domain/repositories/ride_repository.dart';
import '../../features/passenger/domain/repositories/booking_repository.dart';
import '../../features/safety/domain/repositories/safety_repository.dart';
import '../../features/safety/domain/models/complaint.dart';
import '../../features/driver/domain/models/driver_fee_payment.dart';
import '../../features/profile/data/document_service.dart';
import '../../features/passenger/data/api_ride_repository.dart';
import '../../features/passenger/data/api_booking_repository.dart';
import '../../features/safety/data/api_safety_repository.dart';

// Singletons for Mock Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  ref.onDispose(apiClient.close);
  return ApiAuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);
});

final documentServiceProvider = Provider<DocumentService>((ref) {
  final tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  ref.onDispose(apiClient.close);
  return DocumentService(apiClient);
});

final myDocumentsProvider = FutureProvider<List<VerificationDocument>>((
  ref,
) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return [];
  }
  return ref.watch(documentServiceProvider).getMyDocuments();
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  final tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  ref.onDispose(apiClient.close);
  return ApiRideRepository(apiClient);
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  ref.onDispose(apiClient.close);
  return ApiBookingRepository(apiClient);
});

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  final tokenStorage = SecureTokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  ref.onDispose(apiClient.close);
  return ApiSafetyRepository(apiClient);
});

// Auth State Notifier
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    restoreSession();
  }

  Future<void> restoreSession() async {
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(
        email: email,
        password: password,
        role: role,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> registerPassenger({
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
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerPassenger(
        name: name,
        phone: phone,
        email: email,
        password: password,
        cnic: cnic,
        university: university,
        studentId: studentId,
        programSemester: programSemester,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        documents: documents,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> registerDriver({
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
    state = const AsyncValue.loading();
    try {
      final user = await _repo.registerDriver(
        name: name,
        phone: phone,
        email: email,
        password: password,
        cnic: cnic,
        city: city,
        licenseNumber: licenseNumber,
        vehicleMake: vehicleMake,
        vehicleColor: vehicleColor,
        vehiclePlate: vehiclePlate,
        vehicleYear: vehicleYear,
        seatsTotal: seatsTotal,
        vehicleRegistration: vehicleRegistration,
        documents: documents,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> simulateApproval(String email) async {
    await _repo.simulateApproval(email);
    final current = state.value;
    if (current != null && current.email.toLowerCase() == email.toLowerCase()) {
      state = AsyncValue.data(
        current.copyWith(status: VerificationStatus.approved),
      );
    }
  }

  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _repo.updatePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(password: newPassword));
    }
  }

  Future<void> updatePassengerProfile({
    required String name,
    required String phone,
    required String university,
    required String studentId,
    required String programSemester,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    final user = await _repo.updatePassengerProfile(
      name: name,
      phone: phone,
      university: university,
      studentId: studentId,
      programSemester: programSemester,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );
    state = AsyncValue.data(user);
  }

  Future<void> updateDriverProfile({
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
    final user = await _repo.updateDriverProfile(
      name: name,
      phone: phone,
      city: city,
      licenseNumber: licenseNumber,
      vehicleRegistration: vehicleRegistration,
      vehicleMake: vehicleMake,
      vehicleColor: vehicleColor,
      vehiclePlate: vehiclePlate,
      vehicleYear: vehicleYear,
      seatsTotal: seatsTotal,
    );
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> resetDemoData() async {
    await _repo.resetDemoData();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final repo = ref.watch(authRepositoryProvider);
      return AuthNotifier(repo);
    });

// Search filter state for Passenger Home
class SearchFilter {
  final String pickup;
  final String destination;
  final DateTime? departureDate;
  final int seatsNeeded;

  const SearchFilter({
    this.pickup = '',
    this.destination = '',
    this.departureDate,
    this.seatsNeeded = 1,
  });

  SearchFilter copyWith({
    String? pickup,
    String? destination,
    DateTime? departureDate,
    int? seatsNeeded,
  }) {
    return SearchFilter(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      departureDate: departureDate ?? this.departureDate,
      seatsNeeded: seatsNeeded ?? this.seatsNeeded,
    );
  }
}

class PassengerNotificationPreferences {
  final bool bookingUpdates;
  final bool tripReminders;
  final bool safetyAlerts;

  const PassengerNotificationPreferences({
    this.bookingUpdates = true,
    this.tripReminders = true,
    this.safetyAlerts = true,
  });

  PassengerNotificationPreferences copyWith({
    bool? bookingUpdates,
    bool? tripReminders,
    bool? safetyAlerts,
  }) {
    return PassengerNotificationPreferences(
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      tripReminders: tripReminders ?? this.tripReminders,
      safetyAlerts: safetyAlerts ?? this.safetyAlerts,
    );
  }
}

final passengerNotificationPreferencesProvider =
    StateProvider<PassengerNotificationPreferences>((ref) {
      return const PassengerNotificationPreferences();
    });

final searchFilterProvider = StateProvider<SearchFilter>((ref) {
  return const SearchFilter();
});

// Available Rides Provider
final availableRidesProvider = FutureProvider<List<Ride>>((ref) async {
  final repo = ref.watch(rideRepositoryProvider);
  final filter = ref.watch(searchFilterProvider);
  return repo.getAvailableRides(
    pickupQuery: filter.pickup,
    destinationQuery: filter.destination,
    departureDate: filter.departureDate,
    seatsNeeded: filter.seatsNeeded,
  );
});

final allAvailableRidesProvider = FutureProvider<List<Ride>>((ref) async {
  final repo = ref.watch(rideRepositoryProvider);
  return repo.getAvailableRides();
});

final rideByIdProvider = FutureProvider.family<Ride?, int>((ref, rideId) {
  return ref.watch(rideRepositoryProvider).getRideById(rideId);
});

final driverRidesProvider = FutureProvider.family<List<Ride>, String>((
  ref,
  email,
) {
  return ref.watch(rideRepositoryProvider).getDriverRides(email);
});

final driverOnlineProvider = FutureProvider.family<bool, String>((ref, email) {
  return ref.watch(rideRepositoryProvider).isDriverOnline(email);
});

final openPassengerRideRequestsProvider =
    FutureProvider<List<PassengerRideRequest>>((ref) {
      return ref.watch(rideRepositoryProvider).getOpenPassengerRideRequests();
    });

// Passenger Ride Requests Provider
final passengerRideRequestsProvider =
    FutureProvider.family<List<PassengerRideRequest>, String>((
      ref,
      email,
    ) async {
      final repo = ref.watch(rideRepositoryProvider);
      return repo.getPassengerRideRequests(email);
    });

// Selected Booking Tab State
final bookingTabProvider = StateProvider<BookingStatus>((ref) {
  return BookingStatus.pending;
});

// Passenger Bookings Provider
final passengerBookingsProvider = FutureProvider.family<List<Booking>, String>((
  ref,
  email,
) async {
  final repo = ref.watch(bookingRepositoryProvider);
  final tab = ref.watch(bookingTabProvider);
  return repo.getBookings(email, status: tab);
});

final allPassengerBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, email) {
      return ref.watch(bookingRepositoryProvider).getBookings(email);
    });

final driverBookingsProvider = FutureProvider.family<List<Booking>, String>((
  ref,
  email,
) {
  return ref.watch(bookingRepositoryProvider).getDriverBookings(email);
});

final driverFeePaymentsProvider =
    StateProvider.family<List<DriverFeePayment>, String>(
      (ref, email) => const [],
    );

// Chat Messages Provider
final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, int>((
  ref,
  bookingId,
) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.getChatMessages(bookingId);
});

// Notifications Provider
final notificationsProvider =
    FutureProvider.family<List<NotificationItem>, String>((ref, email) async {
      final repo = ref.watch(authRepositoryProvider);
      return repo.getNotifications(email);
    });

final passengerComplaintsProvider =
    FutureProvider.family<List<Complaint>, String>((ref, email) async {
      final repo = ref.watch(safetyRepositoryProvider);
      return repo.getComplaints();
    });
