import 'package:modular_pos/features/policy/ui/models/policy_models.dart';

class VatPolicyDetailArgs {
  const VatPolicyDetailArgs({required this.enabled, required this.ratePercent});

  final bool enabled;
  final double ratePercent;
}

class VatPolicySaveResult {
  const VatPolicySaveResult({required this.enabled, required this.ratePercent});

  final bool enabled;
  final double ratePercent;
}

class KhrRoundingPolicyDetailArgs {
  const KhrRoundingPolicyDetailArgs({
    required this.enabled,
    required this.mode,
    required this.granularity,
  });

  final bool enabled;
  final String mode;
  final String granularity;
}

class KhrRoundingPolicySaveResult {
  const KhrRoundingPolicySaveResult({
    required this.enabled,
    required this.mode,
    required this.granularity,
  });

  final bool enabled;
  final String mode;
  final String granularity;
}

class PolicyItemDetailArgs {
  const PolicyItemDetailArgs({required this.item, required this.value});

  final PolicyItem item;
  final dynamic value;
}
