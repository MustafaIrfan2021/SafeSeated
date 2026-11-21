enum DriverFeePaymentStatus {
  pending('Pending'),
  approved('Approved');

  final String label;
  const DriverFeePaymentStatus(this.label);
}

class DriverFeePayment {
  final DateTime submittedAt;
  final int amount;
  final String reference;
  final String method;
  final DriverFeePaymentStatus status;

  const DriverFeePayment({
    required this.submittedAt,
    required this.amount,
    required this.reference,
    required this.method,
    this.status = DriverFeePaymentStatus.pending,
  });

  DriverFeePayment copyWith({DriverFeePaymentStatus? status}) =>
      DriverFeePayment(
        submittedAt: submittedAt,
        amount: amount,
        reference: reference,
        method: method,
        status: status ?? this.status,
      );
}
