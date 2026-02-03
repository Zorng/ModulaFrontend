import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/branch/ui/view/branches/branch_detail_page.dart';
import 'package:modular_pos/features/branch/ui/view/branches/branch_list_page.dart';

/// Build branch management routes
List<GoRoute> buildBranchRoutes() {
  return [
    GoRoute(
      path: AppRoute.branches.path,
      name: AppRoute.branches.name,
      builder: (context, state) => const BranchListPage(),
    ),
    GoRoute(
      path: AppRoute.branchDetail.path,
      name: AppRoute.branchDetail.name,
      builder: (context, state) {
        final branchId = state.extra as String?;
        if (branchId == null) {
          throw Exception('Branch ID required');
        }
        return BranchDetailPage(branchId: branchId);
      },
    ),
  ];
}
