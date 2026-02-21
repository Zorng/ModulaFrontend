import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_check/attendance_check_page.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_history/attendance_history_page.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance_shell/attendance_bottom_nav_shell_page.dart';

List<RouteBase> buildAttendanceRoutes() {
  return [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AttendanceBottomNavShellPage(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoute.attendance.path,
              name: AppRoute.attendance.name,
              builder: (context, state) => const AttendanceCheckPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '${AppRoute.attendance.path}/history',
              name: 'attendanceHistory',
              builder: (context, state) => const AttendanceHistoryPage(),
            ),
          ],
        ),
      ],
    ),
  ];
}
