import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/staff_attendance/ui/view/attendance/attendance_page.dart';

List<RouteBase> buildAttendanceRoutes() {
  return [
    GoRoute(
      path: AppRoute.attendance.path,
      name: AppRoute.attendance.name,
      builder: (context, state) => const AttendancePage(),
    ),
  ];
}
