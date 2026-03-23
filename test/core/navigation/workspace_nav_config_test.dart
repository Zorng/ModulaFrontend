import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/widgets/navigation/app_navigation_config.dart';
import 'package:modular_pos/features/auth/domain/auth_role.dart';

void main() {
  List<String> labels(List<AppNavigationSection> sections) {
    return [
      for (final section in sections)
        for (final destination in section.destinations) destination.label,
    ];
  }

  test('owner/admin tenant layer shows tenant destinations only', () {
    final sections = buildAppNavigationSections(
      role: AuthRole.admin,
      layer: AppNavigationLayer.tenant,
    );

    expect(labels(sections), [
      'Branches',
      'Menu',
      'Inventory',
      'Staff',
      'Discounts',
    ]);
  });

  test('owner/admin branch layer shows branch destinations only', () {
    final sections = buildAppNavigationSections(
      role: AuthRole.admin,
      layer: AppNavigationLayer.branch,
    );

    expect(labels(sections), [
      'Cash Sessions',
      'Policy',
      'Sale',
      'Active Discount',
    ]);
  });

  test('cashier branch layer shows branch operations only', () {
    final sections = buildAppNavigationSections(
      role: AuthRole.cashier,
      layer: AppNavigationLayer.branch,
    );

    expect(labels(sections), [
      'Cash Sessions',
      'Sale',
      'Active Discount',
      'Attendance',
    ]);
  });

  test('manager branch layer includes attendance management', () {
    final sections = buildAppNavigationSections(
      role: AuthRole.manager,
      layer: AppNavigationLayer.branch,
    );

    expect(labels(sections), [
      'Cash Sessions',
      'Sale',
      'Active Discount',
      'Attendance',
      'Attendance Management',
    ]);
  });

  test('staff tenant layer is empty', () {
    final sections = buildAppNavigationSections(
      role: AuthRole.cashier,
      layer: AppNavigationLayer.tenant,
    );

    expect(sections, isEmpty);
  });
}
