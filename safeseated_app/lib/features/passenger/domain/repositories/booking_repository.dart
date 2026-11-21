import '../models/booking.dart';
import '../models/chat_message.dart';

abstract class BookingRepository {
  Future<List<Booking>> getBookings(
    String passengerEmail, {
    BookingStatus? status,
  });
  Future<Booking?> getBookingById(int id);
  Future<Booking> createBooking({
    required int rideId,
    required String passengerEmail,
    required String passengerName,
    required int seats,
    required String pickupTime,
    required int totalFare,
  });
  Future<Booking> offerRideForPassengerRequest({
    required int requestId,
    required String driverEmail,
    required String driverName,
    required int farePerSeat,
    required int seatsOffered,
    required int vehicleSeatCapacity,
    required String vehicleInfo,
    required String vehiclePlate,
  });
  Future<void> cancelBooking(int bookingId);
  Future<List<Booking>> getDriverBookings(
    String driverEmail, {
    BookingStatus? status,
  });
  Future<void> updateDriverBookingStatus({
    required int bookingId,
    required String driverEmail,
    required BookingStatus status,
  });
  Future<void> rateDriver({
    required int bookingId,
    required int rating,
    required String reviewText,
  });
  Future<List<ChatMessage>> getChatMessages(int bookingId);
  Future<ChatMessage> sendChatMessage({
    required int bookingId,
    required String fromEmail,
    required String text,
  });
}
