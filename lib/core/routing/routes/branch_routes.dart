import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_detail/branch_management_page.dart';
import 'package:modular_pos/features/branchV2/ui/view/branch_selection/branch_selection_page.dart';
import 'package:modular_pos/features/branch_subscription/ui/view/branch_subscription_page.dart';

List<RouteBase> buildBranchRoutes() {
  return [
    GoRoute(
      path: AppRoute.branch.path,
      name: AppRoute.branch.name,
      builder: (context, state) =>
          const BranchSelectionPage(mode: BranchPageMode.destination),
    ),
    GoRoute(
      path: AppRoute.branchDetail.path,
      name: AppRoute.branchDetail.name,
      builder: (context, state) =>
          BranchManagementPage(branchId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: AppRoute.branchSubscription.path,
      name: AppRoute.branchSubscription.name,
      builder: (context, state) => const BranchSubscriptionPage(),
    ),
  ];
}
