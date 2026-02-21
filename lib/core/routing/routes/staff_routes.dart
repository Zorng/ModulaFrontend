import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance/staff_attendance_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_add_placeholder/staff_add_placeholder_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_home/staff_home_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_request/staff_request_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shell/staff_bottom_nav_shell_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/staff_management_page.dart';

List<RouteBase> buildStaffRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return StaffBottomNavShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.staff.path,
              name: AppRoute.staff.name,
              builder: (context, state) => const StaffHomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.attendanceManagement.path,
              name: AppRoute.attendanceManagement.name,
              builder: (context, state) => const StaffAttendancePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.staffRequests.path,
              name: AppRoute.staffRequests.name,
              builder: (context, state) => const StaffRequestPage(),
            ),
          ],
        ),
      ],
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
        return StaffManagementPage(initialStaff: staff, staffId: staffId);
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
