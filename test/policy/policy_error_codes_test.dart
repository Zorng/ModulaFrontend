import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/policy/data/dto/policy_api_envelope.dart';
import 'package:modular_pos/features/policy/data/policy_error_codes.dart';

void main() {
  group('PolicyErrorCodes', () {
    test('normalize canonicalizes known contract codes', () {
      expect(
        PolicyErrorCodes.normalize(' policy_validation_failed '),
        PolicyErrorCodes.policyValidationFailed,
      );
      expect(
        PolicyErrorCodes.normalize('no_branch_access'),
        PolicyErrorCodes.noBranchAccess,
      );
    });

    test('isOffline recognizes normalized offline code', () {
      expect(
        PolicyErrorCodes.isOffline(' offline_unreachable '),
        isTrue,
      );
    });
  });

  group('PolicyApiEnvelope', () {
    test('normalizes reasonCode values before throwing', () {
      expect(
        () => PolicyApiEnvelope.unwrapDataMap(
          {
            'success': false,
            'error': 'Write blocked.',
            'reasonCode': ' subscription_frozen ',
          },
        ),
        throwsA(
          isA<ApiClientException>()
              .having(
                (error) => error.code,
                'code',
                PolicyErrorCodes.subscriptionFrozen,
              )
              .having((error) => error.message, 'message', 'Write blocked.'),
        ),
      );
    });
  });
}
