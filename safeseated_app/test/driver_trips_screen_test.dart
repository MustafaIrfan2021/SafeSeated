import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeseated_app/core/providers/app_providers.dart';
import 'package:safeseated_app/features/auth/data/mock_auth_repository.dart';
import 'package:safeseated_app/features/auth/domain/models/user.dart';
import 'package:safeseated_app/features/auth/domain/models/user_role.dart';
import 'package:safeseated_app/features/auth/domain/models/verification_status.dart';
import 'package:safeseated_app/features/driver/presentation/screens/driver_trips_screen.dart';
import 'package:safeseated_app/features/passenger/domain/models/booking.dart';
import 'package:safeseated_app/features/passenger/domain/repositories/booking_repository.dart';

class _SignedInAuthNotifier extends AuthNotifier {
  _SignedInAuthNotifier() : super(MockAuthRepository()) {
    state = AsyncValue.data(
      const User(
        id: 'driver-id',
        name: 'Driver',
        email: 'driver@example.com',
        phone: '03000000001',
        password: 'unused',
        role: UserRole.driver,
        status: VerificationStatus.approved,
      ),
    );
  }

  @override
  Future<void> restoreSession() async {}
}

class _CountingBookingRepository implements BookingRepository {
  int driverBookingLoads = 0;

  @override
  Future<List<Booking>> getDriverBookings(
    String driverEmail, {
    BookingStatus? status,
  }) async {
    driverBookingLoads++;
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('refreshes driver bookings when the Requests tab is opened', (
    tester,
  ) async {
    var requestsTabActive = false;
    final repository = _CountingBookingRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => _SignedInAuthNotifier()),
          bookingRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                Expanded(
                  child: DriverTripsScreen(isActive: requestsTabActive),
                ),
                TextButton(
                  onPressed: () => setState(() => requestsTabActive = true),
                  child: const Text('Open requests'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(repository.driverBookingLoads, 1);

    await tester.tap(find.text('Open requests'));
    await tester.pumpAndSettle();

    expect(repository.driverBookingLoads, 2);
  });
}
