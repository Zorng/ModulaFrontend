import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/policy/ui/view/policy/policy_page.dart';
import 'package:modular_pos/features/policy/ui/view/policy/policy_route_args.dart';
import 'package:modular_pos/features/policy/ui/view/policy_detail/policy_detail_page.dart';
import 'package:modular_pos/features/policy/ui/view/vat_policy_detail/vat_policy_detail_page.dart';

List<RouteBase> buildPolicyRoutes() {
  return [
    GoRoute(
      path: AppRoute.policy.path,
      name: AppRoute.policy.name,
      builder: (context, state) => const PolicyPage(),
    ),
    GoRoute(
      path: AppRoute.policyVatDetail.path,
      name: AppRoute.policyVatDetail.name,
      builder: (context, state) {
        final args = state.extra as VatPolicyDetailArgs;
        final rateText = args.ratePercent == args.ratePercent.roundToDouble()
            ? args.ratePercent.toInt().toString()
            : args.ratePercent.toString();
        return VatPolicyDetailPage(
          enabled: args.enabled,
          currentRate: '$rateText%',
        );
      },
    ),
    GoRoute(
      path: AppRoute.policyItemDetail.path,
      name: AppRoute.policyItemDetail.name,
      builder: (context, state) {
        final args = state.extra as PolicyItemDetailArgs;
        return PolicyDetailPage(item: args.item, value: args.value);
      },
    ),
  ];
}
