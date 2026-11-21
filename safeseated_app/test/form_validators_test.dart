import 'package:flutter_test/flutter_test.dart';
import 'package:safeseated_app/core/validation/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('validates email addresses', () {
      expect(FormValidators.isValidEmail('passenger@example.com'), isTrue);
      expect(FormValidators.isValidEmail('not-an-email'), isFalse);
      expect(FormValidators.isValidEmail('passenger@invalid'), isFalse);
    });

    test('validates Pakistan mobile formats', () {
      expect(FormValidators.isValidPakistanPhone('0312-5550142'), isTrue);
      expect(FormValidators.isValidPakistanPhone('+923125550142'), isTrue);
      expect(FormValidators.isValidPakistanPhone('12345'), isFalse);
    });

    test('accepts a 13-digit CNIC with or without separators', () {
      expect(FormValidators.isValidCnic('42101-1234567-8'), isTrue);
      expect(FormValidators.isValidCnic('4210112345678'), isTrue);
      expect(FormValidators.isValidCnic('42101-1234'), isFalse);
    });

    test('validates vehicle model years', () {
      expect(FormValidators.isValidVehicleYear('2022'), isTrue);
      expect(FormValidators.isValidVehicleYear(' 2022 '), isTrue);
      expect(FormValidators.isValidVehicleYear('not a year'), isFalse);
      expect(FormValidators.isValidVehicleYear('1890'), isFalse);
      expect(
        FormValidators.isValidVehicleYear('${DateTime.now().year + 2}'),
        isFalse,
      );
    });
  });
}
