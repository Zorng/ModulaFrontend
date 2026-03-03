import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/branch_subscription/ui/view/branch_subscription_page.dart';

List<RouteBase> buildBranchRoutes() {
  return [
    // GoRoute(
    //   path: AppRoute.branch.path,
    //   name: AppRoute.branch.name,
    //   builder: (context, state) => const BranchListPage(),
    // ),
    // GoRoute(
    //   path: AppRoute.branchDetail.path,
    //   name: AppRoute.branchDetail.name,
    //   builder: (context, state) {
    //     final branchId = state.pathParameters['id'] ?? '';
    //     return BranchDetailPage(branchId: branchId);
    //   },
    // ),
    GoRoute(
      path: AppRoute.branchSubscription.path,
      name: AppRoute.branchSubscription.name,
      builder: (context, state) => const BranchSubscriptionPage(),
    ),
  ];
}
