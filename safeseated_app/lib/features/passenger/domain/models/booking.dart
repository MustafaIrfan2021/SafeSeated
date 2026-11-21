enum BookingStatus {
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  rejected('rejected', 'Rejected'),
  cancelled('cancelled', 'Cancelled'),
  active('active', 'In progress'),
  completed('completed', 'Completed');

  final String code;
  final String label;

  const BookingStatus(this.code, this.label);

  static BookingStatus fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'accepted':
        return BookingStatus.accepted;
      case 'rejected':
        return BookingStatus.rejected;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'active':
        return BookingStatus.active;
      case 'completed':
        return BookingStatus.completed;
      default:
        throw ArgumentError.value(code, 'code', 'Unknown booking status');
    }
  }
}

class Booking {
  final int id;
  final int rideId;
  final String passengerEmail;
  final String passengerName;
  final BookingStatus status;
  final String date;
  final int seats;
  final String pickupTime;
  final int totalFare;
  final int? rating;
  final String? reviewText;

  const Booking({
    required this.id,
    required this.rideId,
    required this.passengerEmail,
    required this.passengerName,
    required this.status,
    required this.date,
    this.seats = 1,
    required this.pickupTime,
    required this.totalFare,
    this.rating,
    this.reviewText,
  });

  Booking copyWith({
    int? id,
    int? rideId,
    String? passengerEmail,
    String? passengerName,
    BookingStatus? status,
    String? date,
    int? seats,
    String? pickupTime,
    int? totalFare,
    int? rating,
    String? reviewText,
  }) {
    return Booking(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerEmail: passengerEmail ?? this.passengerEmail,
      passengerName: passengerName ?? this.passengerName,
      status: status ?? this.status,
      date: date ?? this.date,
      seats: seats ?? this.seats,
      pickupTime: pickupTime ?? this.pickupTime,
      totalFare: totalFare ?? this.totalFare,
      rating: rating ?? this.rating,
      reviewText: reviewText ?? this.reviewText,
    );
  }
}
