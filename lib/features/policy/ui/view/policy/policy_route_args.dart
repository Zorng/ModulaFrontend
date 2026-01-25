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

class PolicyItemDetailArgs {
  const PolicyItemDetailArgs({required this.item, required this.value});

  final PolicyItem item;
  final dynamic value;
}
