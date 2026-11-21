class FormValidators {
  const FormValidators._();

  static bool isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  static bool isValidPakistanPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return (digits.length == 11 && digits.startsWith('03')) ||
        (digits.length == 12 && digits.startsWith('923')) ||
        (digits.length == 14 && digits.startsWith('00923'));
  }

  static bool isValidCnic(String value) {
    return value.replaceAll(RegExp(r'\D'), '').length == 13;
  }

  static bool isValidVehicleYear(String value) {
    final year = int.tryParse(value.trim());
    return year != null && year >= 1990 && year <= DateTime.now().year + 1;
  }
}
