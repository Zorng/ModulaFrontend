import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/phone_input.dart';

void main() {
  test('normalizePhoneInput removes common separators but keeps prefixes', () {
    expect(normalizePhoneInput('012 678 990'), '012678990');
    expect(normalizePhoneInput('+855 12-678-990'), '+85512678990');
    expect(normalizePhoneInput('(012) 678 990'), '012678990');
  });

  test(
    'isAcceptedPhoneInput accepts Cambodia local and international input',
    () {
      expect(isAcceptedPhoneInput('012678990'), isTrue);
      expect(isAcceptedPhoneInput('012 678 990'), isTrue);
      expect(isAcceptedPhoneInput('85512678990'), isTrue);
      expect(isAcceptedPhoneInput('+85512678990'), isTrue);
    },
  );

  test('isAcceptedPhoneInput still accepts generic E.164 input', () {
    expect(isAcceptedPhoneInput('+12345678901'), isTrue);
  });

  test('isAcceptedPhoneInput rejects empty or malformed values', () {
    expect(isAcceptedPhoneInput(''), isFalse);
    expect(isAcceptedPhoneInput('abc123'), isFalse);
    expect(isAcceptedPhoneInput('12345'), isFalse);
  });
}
