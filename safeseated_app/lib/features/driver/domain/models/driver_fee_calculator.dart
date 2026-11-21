int calculatePlatformFee(int completedFareTotal) {
  if (completedFareTotal < 0) {
    throw ArgumentError.value(completedFareTotal, 'completedFareTotal');
  }
  return (completedFareTotal * 20 / 100).round();
}

int calculateFeeDue({
  required int completedFareTotal,
  required int submittedTotal,
}) {
  if (submittedTotal < 0) {
    throw ArgumentError.value(submittedTotal, 'submittedTotal');
  }
  final fee = calculatePlatformFee(completedFareTotal);
  return (fee - submittedTotal).clamp(0, fee).toInt();
}
