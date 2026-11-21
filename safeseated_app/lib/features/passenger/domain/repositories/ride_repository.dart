import '../models/ride.dart';
import '../models/ride_request.dart';

abstract class RideRepository {
  Future<List<Ride>> getAvailableRides({
    String? pickupQuery,
    String? destinationQuery,
    DateTime? departureDate,
    int seatsNeeded = 1,
  });
  Future<Ride?> getRideById(int id);
  Future<List<PassengerRideRequest>> getPassengerRideRequests(
    String passengerEmail,
  );
  Future<PassengerRideRequest> createPassengerRideRequest({
    required String passengerEmail,
    required String passengerName,
    required String pickup,
    required String destination,
    required String time,
    required int seats,
  });
  Future<void> cancelPassengerRideRequest(int requestId);
  Future<List<Ride>> getDriverRides(String driverEmail);
  Future<Ride> publishDriverRide({
    required String driverEmail,
    required String driverName,
    required String from,
    required String to,
    required DateTime departureAt,
    required String departureTime,
    required int farePerSeat,
    required int seatsTotal,
    required String vehicleInfo,
    required String vehiclePlate,
    String notes = '',
  });
  Future<Ride> updateDriverRide({
    required int rideId,
    required String driverEmail,
    required String from,
    required String to,
    required DateTime departureAt,
    required String departureTime,
    required int farePerSeat,
    required int seatsTotal,
    required String notes,
  });
  Future<void> cancelDriverRide(int rideId, String driverEmail);
  Future<void> reserveRideSeats(int rideId, int seats);
  Future<void> releaseRideSeats(int rideId, int seats);
  Future<List<PassengerRideRequest>> getOpenPassengerRideRequests();
  Future<void> fulfillPassengerRideRequest(
    int requestId,
    String driverEmail,
    String driverName,
  );
  Future<bool> isDriverOnline(String driverEmail);
  Future<void> setDriverOnline(String driverEmail, bool isOnline);
}
