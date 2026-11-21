enum VerificationStatus {
  pending('pending', 'Pending Review'),
  approved('approved', 'Verified'),
  rejected('rejected', 'Rejected'),
  suspended('suspended', 'Suspended');

  final String code;
  final String label;

  const VerificationStatus(this.code, this.label);

  static VerificationStatus fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'pending':
        return VerificationStatus.pending;
      case 'approved':
      case 'verified':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'suspended':
        return VerificationStatus.suspended;
      default:
        return VerificationStatus.pending;
    }
  }
}
