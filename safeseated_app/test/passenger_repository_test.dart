import 'package:flutter_test/flutter_test.dart';
import 'package:safeseated_app/features/auth/data/mock_auth_repository.dart';
import 'package:safeseated_app/features/passenger/data/mock_booking_repository.dart';
import 'package:safeseated_app/features/passenger/data/mock_ride_repository.dart';
import 'package:safeseated_app/features/passenger/domain/models/booking.dart';
import 'package:safeseated_app/features/passenger/domain/models/ride_request.dart';
import 'package:safeseated_app/features/auth/domain/models/user_role.dart';
import 'package:safeseated_app/features/auth/domain/models/verification_status.dart';

void main() {
  group('MockRideRepository', () {
    test('filters available rides by route, date and seat count', () async {
      final repository = MockRideRepository();
      final date = DateTime.now().add(const Duration(days: 2));
      final rides = await repository.getAvailableRides(
        pickupQuery: 'DHA',
        destinationQuery: 'SMIU',
        departureDate: DateTime(date.year, date.month, date.day),
        seatsNeeded: 3,
      );

      expect(rides.map((ride) => ride.id), [3]);
    });

    test('rejects invalid seat counts', () async {
      final repository = MockRideRepository();

      await expectLater(
        repository.getAvailableRides(seatsNeeded: 0),
        throwsArgumentError,
      );
    });

    test('cancellation remains visible as a cancelled request', () async {
      final repository = MockRideRepository();
      await repository.cancelPassengerRideRequest(101);

      final requests = await repository.getPassengerRideRequests(
        'ayesha@smiu.edu.pk',
      );
      expect(requests, hasLength(1));
      expect(requests.single.status, PassengerRideRequestStatus.cancelled);
    });

    test('rejects invalid custom ride requests', () async {
      final repository = MockRideRepository();

      await expectLater(
        repository.createPassengerRideRequest(
          passengerEmail: 'passenger@example.com',
          passengerName: 'Passenger',
          pickup: 'Gulshan',
          destination: 'SMIU',
          time: '8:00 AM',
          seats: 5,
        ),
        throwsArgumentError,
      );
    });
  });

  group('MockBookingRepository', () {
    test('cancels a pending booking without marking it rejected', () async {
      final repository = MockBookingRepository(MockRideRepository());
      await repository.cancelBooking(1);

      final bookings = await repository.getBookings('ayesha@smiu.edu.pk');
      final cancelled = bookings.singleWhere((booking) => booking.id == 1);
      expect(cancelled.status, BookingStatus.cancelled);
    });

    test('allows one rating for a completed booking only', () async {
      final repository = MockBookingRepository(MockRideRepository());
      await repository.rateDriver(
        bookingId: 4,
        rating: 5,
        reviewText: 'On time',
      );

      await expectLater(
        repository.rateDriver(bookingId: 4, rating: 4, reviewText: 'Duplicate'),
        throwsStateError,
      );
      await expectLater(
        repository.rateDriver(
          bookingId: 1,
          rating: 5,
          reviewText: 'Not completed',
        ),
        throwsStateError,
      );
    });
  });

  test('passenger profile edits persist in the active mock session', () async {
    final repository = MockAuthRepository();
    await repository.login(
      email: 'ayesha@smiu.edu.pk',
      password: '1234',
      role: UserRole.passenger,
    );
    await repository.updatePassengerProfile(
      name: 'Ayesha Khan',
      phone: '0312-5550142',
      university: 'SMIU',
      studentId: 'CSC-22F-042',
      programSemester: 'BSCS - 5th Semester',
      emergencyContactName: 'Rubina Khan',
      emergencyContactPhone: '0300-1112233',
    );

    final user = await repository.getCurrentUser();
    expect(user?.emergencyContactName, 'Rubina Khan');
    expect(user?.emergencyContactPhone, '0300-1112233');
    expect(user?.status, VerificationStatus.pending);
  });

  test('passenger registration rejects invalid contact details', () async {
    final repository = MockAuthRepository();
    await expectLater(
      repository.registerPassenger(
        name: 'New Passenger',
        phone: '12345',
        email: 'not-an-email',
        password: 'pass1234',
        cnic: '42101-5544332-6',
        university: 'SMIU',
        studentId: 'CSC-23F-001',
        programSemester: 'BSCS - 1st Semester',
        emergencyContactName: 'Emergency Contact',
        emergencyContactPhone: '0300-1112233',
        documents: const [
          'CNIC (front & back)',
          'University ID card',
          'Selfie photo',
        ],
      ),
      throwsArgumentError,
    );
  });

  test(
    'registered passenger can log in with the registered credentials',
    () async {
      final repository = MockAuthRepository();
      await repository.registerPassenger(
        name: 'New Passenger',
        phone: '0321-9876543',
        email: 'new.passenger@example.com',
        password: 'pass1234',
        cnic: '42101-5544332-6',
        university: 'SMIU',
        studentId: 'CSC-23F-001',
        programSemester: 'BSCS - 1st Semester',
        emergencyContactName: 'Emergency Contact',
        emergencyContactPhone: '0300-1112233',
        documents: const [
          'CNIC (front & back)',
          'University ID card',
          'Selfie photo',
        ],
      );
      await repository.logout();

      final user = await repository.login(
        email: 'NEW.PASSENGER@example.com',
        password: 'pass1234',
        role: UserRole.passenger,
      );

      expect(user.email, 'new.passenger@example.com');
      expect(user.role, UserRole.passenger);
      expect(user.status, VerificationStatus.pending);
    },
  );

  test(
    'unknown email and incorrect password return the same login message',
    () async {
      final repository = MockAuthRepository();

      for (final credentials in [
        ('unknown@example.com', 'pass1234'),
        ('ayesha@smiu.edu.pk', 'incorrect'),
      ]) {
        await expectLater(
          repository.login(
            email: credentials.$1,
            password: credentials.$2,
            role: UserRole.passenger,
          ),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              'Exception: Incorrect username or password.',
            ),
          ),
        );
      }
    },
  );
}
