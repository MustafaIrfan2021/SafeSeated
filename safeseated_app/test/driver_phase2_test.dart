import 'package:flutter_test/flutter_test.dart';
import 'package:safeseated_app/core/constants/app_routes.dart';
import 'package:safeseated_app/core/router/app_router.dart';
import 'package:safeseated_app/features/auth/data/mock_auth_repository.dart';
import 'package:safeseated_app/features/auth/domain/models/user.dart';
import 'package:safeseated_app/features/auth/domain/models/user_role.dart';
import 'package:safeseated_app/features/auth/domain/models/verification_status.dart';
import 'package:safeseated_app/features/driver/domain/models/driver_fee_calculator.dart';
import 'package:safeseated_app/features/passenger/data/mock_booking_repository.dart';
import 'package:safeseated_app/features/passenger/data/mock_ride_repository.dart';
import 'package:safeseated_app/features/passenger/domain/models/booking.dart';

void main() {
  group('Driver registration and profile', () {
    test('registers new drivers in pending verification state', () async {
      final repository = MockAuthRepository();
      final driver = await repository.registerDriver(
        name: 'Mariba Ali',
        phone: '0321-9876543',
        email: 'MARIBA@EXAMPLE.COM',
        password: 'pass1234',
        cnic: '42101-5544332-6',
        city: 'Karachi',
        licenseNumber: 'KHI-DL-554433',
        vehicleMake: 'Suzuki Alto',
        vehicleColor: 'Silver',
        vehiclePlate: 'ABC-123',
        vehicleYear: '2022',
        seatsTotal: 3,
        vehicleRegistration: 'ABC-123',
        documents: const [
          'CNIC (front & back)',
          'Driving licence',
          'Vehicle registration book',
          'Vehicle photo',
          'Selfie photo',
        ],
      );

      expect(driver.email, 'mariba@example.com');
      expect(driver.role, UserRole.driver);
      expect(driver.status, VerificationStatus.pending);
      expect(driver.documents, hasLength(5));

      await repository.logout();
      final loggedInDriver = await repository.login(
        email: 'mariba@example.com',
        password: 'pass1234',
        role: UserRole.driver,
      );
      expect(loggedInDriver.id, driver.id);
      expect(loggedInDriver.status, VerificationStatus.pending);

      await expectLater(
        repository.login(
          email: 'mariba@example.com',
          password: 'incorrect',
          role: UserRole.driver,
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            'Exception: Incorrect username or password.',
          ),
        ),
      );
    });

    test(
      'vehicle verification details send an approved driver back to review',
      () async {
        final repository = MockAuthRepository();
        await repository.login(
          email: 'sana@safeseated.pk',
          password: '1234',
          role: UserRole.driver,
        );
        final updated = await repository.updateDriverProfile(
          name: 'Sana Malik',
          phone: '0333-4445566',
          city: 'Karachi',
          licenseNumber: 'KHI-DL-88210',
          vehicleRegistration: 'BCA-412',
          vehicleMake: 'Suzuki Alto VXR',
          vehicleColor: 'Silver',
          vehiclePlate: 'BCA-999',
          vehicleYear: '2022',
          seatsTotal: 3,
          emergencyContactName: '',
          emergencyContactPhone: '',
        );

        expect(updated.status, VerificationStatus.pending);
      },
    );

    test(
      'rejects invalid driver seat capacity and missing documents',
      () async {
        final repository = MockAuthRepository();
        await expectLater(
          repository.registerDriver(
            name: 'Driver',
            phone: '0321-9876543',
            email: 'new@example.com',
            password: 'pass1234',
            cnic: '42101-5544332-6',
            city: 'Karachi',
            licenseNumber: 'DL-1',
            vehicleMake: 'Suzuki Alto',
            vehicleColor: 'Silver',
            vehiclePlate: 'ABC-123',
            vehicleYear: '2022',
            seatsTotal: 5,
            vehicleRegistration: 'ABC-123',
            documents: const [
              'CNIC (front & back)',
              'Driving licence',
              'Vehicle registration book',
              'Vehicle photo',
              'Selfie photo',
            ],
          ),
          throwsArgumentError,
        );
        await expectLater(
          repository.registerDriver(
            name: 'Driver',
            phone: '0321-9876543',
            email: 'new@example.com',
            password: 'pass1234',
            cnic: '42101-5544332-6',
            city: 'Karachi',
            licenseNumber: 'DL-1',
            vehicleMake: 'Suzuki Alto',
            vehicleColor: 'Silver',
            vehiclePlate: 'ABC-123',
            vehicleYear: '2022',
            seatsTotal: 3,
            vehicleRegistration: 'ABC-123',
            documents: const ['CNIC'],
          ),
          throwsArgumentError,
        );
      },
    );

    test('rejects malformed contact and model-year details', () async {
      final repository = MockAuthRepository();
      await expectLater(
        repository.registerDriver(
          name: 'Driver',
          phone: '12345',
          email: 'new@example.com',
          password: 'pass1234',
          cnic: '42101-5544332-6',
          city: 'Karachi',
          licenseNumber: 'DL-1',
          vehicleMake: 'Suzuki Alto',
          vehicleColor: 'Silver',
          vehiclePlate: 'ABC-123',
          vehicleYear: 'not-a-year',
          seatsTotal: 3,
          vehicleRegistration: 'ABC-123',
          documents: const [
            'CNIC (front & back)',
            'Driving licence',
            'Vehicle registration book',
            'Vehicle photo',
            'Selfie photo',
          ],
        ),
        throwsArgumentError,
      );
    });
  });

  group('Driver ride and trip management', () {
    test(
      'booking acceptance reserves capacity and prevents overbooking',
      () async {
        final rides = MockRideRepository();
        final bookings = MockBookingRepository(rides);
        final request = await bookings.createBooking(
          rideId: 4,
          passengerEmail: 'new.passenger@example.com',
          passengerName: 'New Passenger',
          seats: 2,
          pickupTime: '7:45 AM',
          totalFare: 600,
        );

        await bookings.updateDriverBookingStatus(
          bookingId: request.id,
          driverEmail: 'hina@safeseated.pk',
          status: BookingStatus.accepted,
        );

        expect((await rides.getRideById(4))!.seatsBooked, 3);
        await expectLater(rides.reserveRideSeats(4, 1), throwsStateError);
      },
    );

    test(
      'driver booking statuses follow pending, accepted, active, complete',
      () async {
        final rides = MockRideRepository();
        final bookings = MockBookingRepository(rides);
        await bookings.updateDriverBookingStatus(
          bookingId: 1,
          driverEmail: 'hina@safeseated.pk',
          status: BookingStatus.accepted,
        );
        await bookings.updateDriverBookingStatus(
          bookingId: 1,
          driverEmail: 'hina@safeseated.pk',
          status: BookingStatus.active,
        );
        await bookings.updateDriverBookingStatus(
          bookingId: 1,
          driverEmail: 'hina@safeseated.pk',
          status: BookingStatus.completed,
        );

        expect(
          (await bookings.getBookingById(1))!.status,
          BookingStatus.completed,
        );
        await expectLater(
          bookings.updateDriverBookingStatus(
            bookingId: 1,
            driverEmail: 'hina@safeseated.pk',
            status: BookingStatus.rejected,
          ),
          throwsStateError,
        );
      },
    );

    test('offline drivers are hidden and cannot publish rides', () async {
      final repository = MockRideRepository();
      await repository.setDriverOnline('sana@safeseated.pk', false);

      final rides = await repository.getAvailableRides();
      expect(
        rides.every((ride) => ride.driverEmail != 'sana@safeseated.pk'),
        isTrue,
      );
      await expectLater(
        repository.publishDriverRide(
          driverEmail: 'sana@safeseated.pk',
          driverName: 'Sana Malik',
          from: 'Gulshan',
          to: 'SMIU',
          departureAt: DateTime.now().add(const Duration(days: 1)),
          departureTime: '8:00 AM',
          farePerSeat: 300,
          seatsTotal: 3,
          vehicleInfo: 'Suzuki Alto · Silver',
          vehiclePlate: 'BCA-412',
        ),
        throwsStateError,
      );
    });

    test('published rides enforce capacity and cancellation rules', () async {
      final repository = MockRideRepository();
      final ride = await repository.publishDriverRide(
        driverEmail: 'sana@safeseated.pk',
        driverName: 'Sana Malik',
        from: 'Gulshan',
        to: 'SMIU',
        departureAt: DateTime.now().add(const Duration(days: 1)),
        departureTime: '8:00 AM',
        farePerSeat: 300,
        seatsTotal: 3,
        vehicleInfo: 'Suzuki Alto · Silver',
        vehiclePlate: 'BCA-412',
      );
      await repository.reserveRideSeats(ride.id, 2);

      await expectLater(
        repository.updateDriverRide(
          rideId: ride.id,
          driverEmail: 'sana@safeseated.pk',
          from: 'Gulshan',
          to: 'SMIU',
          departureAt: DateTime.now().add(const Duration(days: 1)),
          departureTime: '8:00 AM',
          farePerSeat: 300,
          seatsTotal: 1,
          notes: '',
        ),
        throwsStateError,
      );
      await expectLater(
        repository.cancelDriverRide(ride.id, 'sana@safeseated.pk'),
        throwsStateError,
      );

      await repository.releaseRideSeats(ride.id, 2);
      await repository.cancelDriverRide(ride.id, 'sana@safeseated.pk');
      expect((await repository.getRideById(ride.id))!.isActive, isFalse);
    });

    test(
      'driver can fulfil an open passenger request only while online',
      () async {
        final repository = MockRideRepository();
        await repository.setDriverOnline('sana@safeseated.pk', false);
        await expectLater(
          repository.fulfillPassengerRideRequest(
            101,
            'sana@safeseated.pk',
            'Sana Malik',
          ),
          throwsStateError,
        );
        await repository.setDriverOnline('sana@safeseated.pk', true);
        await repository.fulfillPassengerRideRequest(
          101,
          'sana@safeseated.pk',
          'Sana Malik',
        );

        final requests = await repository.getPassengerRideRequests(
          'ayesha@smiu.edu.pk',
        );
        expect(requests.single.driverEmail, 'sana@safeseated.pk');
      },
    );

    test(
      'offering a passenger request creates a ride and accepted booking',
      () async {
        final rides = MockRideRepository();
        final bookings = MockBookingRepository(rides);
        final booking = await bookings.offerRideForPassengerRequest(
          requestId: 101,
          driverEmail: 'sana@safeseated.pk',
          driverName: 'Sana Malik',
          farePerSeat: 350,
          seatsOffered: 3,
          vehicleSeatCapacity: 3,
          vehicleInfo: 'Suzuki Alto VXR · Silver',
          vehiclePlate: 'BCA-412',
        );

        final ride = await rides.getRideById(booking.rideId);
        final request = (await rides.getPassengerRideRequests(
          'ayesha@smiu.edu.pk',
        )).single;

        expect(booking.status, BookingStatus.accepted);
        expect(booking.totalFare, 350);
        expect(ride!.from, 'Gulistan-e-Jauhar Block 13');
        expect(ride.to, 'SMIU, Shahrah-e-Faisal');
        expect(ride.seatsBooked, 1);
        expect(request.status.code, 'accepted');
        expect(request.driverEmail, 'sana@safeseated.pk');
      },
    );

    test(
      'passenger request offer cannot exceed the registered capacity',
      () async {
        final rides = MockRideRepository();
        final bookings = MockBookingRepository(rides);
        final initialRides = await rides.getDriverRides('sana@safeseated.pk');

        await expectLater(
          bookings.offerRideForPassengerRequest(
            requestId: 101,
            driverEmail: 'sana@safeseated.pk',
            driverName: 'Sana Malik',
            farePerSeat: 350,
            seatsOffered: 4,
            vehicleSeatCapacity: 3,
            vehicleInfo: 'Suzuki Alto VXR · Silver',
            vehiclePlate: 'BCA-412',
          ),
          throwsArgumentError,
        );

        expect(
          await rides.getDriverRides('sana@safeseated.pk'),
          hasLength(initialRides.length),
        );
        expect(
          (await rides.getPassengerRideRequests(
            'ayesha@smiu.edu.pk',
          )).single.isOpen,
          isTrue,
        );
      },
    );
  });

  group('Driver wallet and authorization', () {
    test('calculates the 20 percent platform fee and outstanding balance', () {
      expect(calculatePlatformFee(1000), 200);
      expect(calculatePlatformFee(3), 1);
      expect(
        calculateFeeDue(completedFareTotal: 1000, submittedTotal: 75),
        125,
      );
      expect(calculateFeeDue(completedFareTotal: 1000, submittedTotal: 250), 0);
    });

    test('protects driver routes and routes approved drivers home', () {
      const driver = User(
        id: 'd1',
        name: 'Driver',
        email: 'driver@example.com',
        phone: '0300',
        password: 'demo',
        role: UserRole.driver,
        status: VerificationStatus.approved,
      );
      const passenger = User(
        id: 'p1',
        name: 'Passenger',
        email: 'passenger@example.com',
        phone: '0300',
        password: 'demo',
        role: UserRole.passenger,
        status: VerificationStatus.approved,
      );
      expect(
        appRouterRedirect(passenger, AppRoutes.driverHome),
        AppRoutes.welcome,
      );
      expect(appRouterRedirect(driver, AppRoutes.login), AppRoutes.driverHome);
      expect(appRouterRedirect(driver, AppRoutes.driverHome), isNull);
      const pendingDriver = User(
        id: 'd2',
        name: 'New Driver',
        email: 'newdriver@example.com',
        phone: '0300',
        password: 'demo',
        role: UserRole.driver,
        status: VerificationStatus.pending,
      );
      expect(appRouterRedirect(pendingDriver, AppRoutes.driverHome), isNull);
    });
  });
}
