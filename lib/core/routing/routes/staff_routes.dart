import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/staff/domain/models/staff_model.dart';
import 'package:modular_pos/features/staff/ui/view/staff_add_placeholder_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_detail_view.dart';
import 'package:modular_pos/features/staff/ui/view/staff_form/staff_form_page.dart';
import 'package:modular_pos/features/staff/ui/view/staff_list_view.dart';

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
        final staff = state.extra as Staff;
        return StaffDetailView(staff: staff);
      },
    ),
    GoRoute(
      path: AppRoute.staffForm.path,
      name: AppRoute.staffForm.name,
      builder: (context, state) {
        final staff = state.extra is Staff ? state.extra as Staff : null;
        return StaffFormView(staff: staff);
      },
    ),
    GoRoute(
      path: AppRoute.staffAdd.path,
      name: AppRoute.staffAdd.name,
      builder: (context, state) => const StaffAddPlaceholderPage(),
    ),
  ];
}
