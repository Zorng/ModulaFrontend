import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/discount/ui/view/discount/discount_page.dart';
import 'package:modular_pos/features/discount/ui/view/discount_rule_detail/discount_rule_detail_page.dart';
import 'package:modular_pos/features/discount/ui/view/discount_rule_form/discount_rule_form_page.dart';

List<RouteBase> buildDiscountRoutes() {
  return [
    GoRoute(
      path: AppRoute.discount.path,
      name: AppRoute.discount.name,
      builder: (context, state) => const DiscountPage(),
    ),
    GoRoute(
      path: AppRoute.discountRuleForm.path,
      name: AppRoute.discountRuleForm.name,
      builder: (context, state) => DiscountRuleFormPage(
        ruleId: state.extra is String ? state.extra as String : null,
      ),
    ),
    GoRoute(
      path: AppRoute.discountRuleDetail.path,
      name: AppRoute.discountRuleDetail.name,
      builder: (context, state) =>
          DiscountRuleDetailPage(ruleId: state.pathParameters['ruleId'] ?? ''),
    ),
  ];
}
