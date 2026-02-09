import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/view/staff_add_placeholder/staff_add_placeholder_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_list/staff_list_view.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/staff_management_page.dart';

List<RouteBase> buildStaffRoutes() {
  return [
    GoRoute(
      path: AppRoute.staff.path,
      name: AppRoute.staff.name,
      builder: (context, state) => const StaffListView(),
    ),
    GoRoute(
      path: AppRoute.staffDetail.path,
      name: AppRoute.staffDetail.name,
      builder: (context, state) {
        final staffId = state.pathParameters['id'];
        Staff? staff;
        if (state.extra is Staff) {
          staff = state.extra as Staff;
        }
        return StaffManagementPage(
          initialStaff: staff,
          staffId: staffId,
        );
      },
    ),
    GoRoute(
      path: AppRoute.staffForm.path,
      name: AppRoute.staffForm.name,
      builder: (context, state) {
        Staff? staff;
        String? branchId;
        if (state.extra is Staff) {
          staff = state.extra as Staff;
        } else if (state.extra is Map<String, dynamic>) {
          final extra = state.extra as Map<String, dynamic>;
          staff = extra['staff'] as Staff?;
          branchId = extra['branchId'] as String?;
        }
        return StaffManagementPage(
          initialStaff: staff,
          initialBranchId: branchId,
        );
      },
    ),
    GoRoute(
      path: AppRoute.staffAdd.path,
      name: AppRoute.staffAdd.name,
      builder: (context, state) => const StaffAddPlaceholderPage(),
    ),
  ];
}
