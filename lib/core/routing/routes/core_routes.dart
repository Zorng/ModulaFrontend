import 'package:go_router/go_router.dart';
import 'package:modular_pos/core/routing/app_router.dart';
import 'package:modular_pos/core/widgets/widget_gallery_page.dart';
import 'package:modular_pos/features/auth/ui/view/login_view.dart';
import 'package:modular_pos/features/auth/ui/view/otp/otp_verification_page.dart';
import 'package:modular_pos/features/auth/ui/view/signup/signup_page.dart';
import 'package:modular_pos/features/branch/ui/view/branch_selection/branch_selection_page.dart';
import 'package:modular_pos/features/tenant/ui/view/tenant_selection/tenant_selection_page.dart';

List<RouteBase> buildCoreRoutes() {
  return [
    GoRoute(
      path: AppRoute.login.path,
      name: AppRoute.login.name,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoute.signup.path,
      name: AppRoute.signup.name,
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: AppRoute.otpVerification.path,
      name: AppRoute.otpVerification.name,
      builder: (context, state) =>
          OtpVerificationPage(initialPhone: state.uri.queryParameters['phone']),
    ),
    GoRoute(
      path: AppRoute.tenantSelection.path,
      name: AppRoute.tenantSelection.name,
      builder: (context, state) => const TenantSelectionPage(),
    ),
    GoRoute(
      path: AppRoute.branchSelection.path,
      name: AppRoute.branchSelection.name,
      builder: (context, state) => const BranchSelectionPage(),
    ),
    GoRoute(
      path: AppRoute.components.path,
      name: AppRoute.components.name,
      builder: (context, state) => const WidgetGalleryPage(),
    ),
  ];
}
