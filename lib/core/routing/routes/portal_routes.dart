import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/features/auth/ui/portals/admin_portal.dart';
import 'package:modular_pos/features/auth/ui/portals/cashier_portal.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

GoRoute buildPortalRoute(Ref ref) {
  return GoRoute(
    path: AppRoute.portal.path,
    name: AppRoute.portal.name,
    builder: (context, state) {
      final session = ref.read(loginControllerProvider).session;
      final role = session?.user.role.trim().toLowerCase() ?? 'cashier';
      return role == 'admin' ? const AdminPortal() : const CashierPortal();
    },
  );
}
