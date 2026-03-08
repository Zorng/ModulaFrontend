import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/staff/ui/view/staff_attendance_review/staff_attendance_review_tab_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_detail/staff_membership_detail_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_invite/staff_invite_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_list/staff_staffs_tab_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shell/staff_bottom_nav_shell_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_shift/staff_shift_tab_page.dart';

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
              builder: (context, state) => const StaffStaffsTabPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.staffAttendance.path,
              name: AppRoute.staffAttendance.name,
              builder: (context, state) => const StaffAttendanceReviewTabPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.staffShift.path,
              name: AppRoute.staffShift.name,
              builder: (context, state) => const StaffShiftTabPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoute.staffDetail.path,
      name: AppRoute.staffDetail.name,
      builder: (context, state) {
        final membershipId = state.pathParameters['membershipId'] ?? '';
        return StaffMembershipDetailPage(membershipId: membershipId);
      },
    ),
    GoRoute(
      path: AppRoute.staffInvite.path,
      name: AppRoute.staffInvite.name,
      builder: (context, state) => const StaffInvitePage(),
    ),
  ];
}
