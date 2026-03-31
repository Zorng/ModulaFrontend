import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/features/auth/domain/models/tenant_membership.dart';
import 'package:modular_pos/features/tenant/ui/view/tenant_selection/widgets/tenant_selection_tile.dart';

import '../test_utils/pump_app.dart';

void main() {
  testWidgets('tenant selection tile omits branch and employee metadata', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Scaffold(
        body: TenantSelectionTile(
          membership: TenantMembership(
            tenantId: 'tenant-1',
            tenantName: 'Cafe Modula',
            role: 'Owner',
            branches: [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cafe Modula'), findsOneWidget);
    expect(find.text('OWNER'), findsOneWidget);
    expect(find.text('Branches'), findsNothing);
    expect(find.text('Employees'), findsNothing);
    expect(find.byIcon(Icons.account_tree_outlined), findsNothing);
    expect(find.byIcon(Icons.people_outline), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    final tileCard = tester.widget<Card>(
      find
          .descendant(
            of: find.byType(TenantSelectionTile),
            matching: find.byType(Card),
          )
          .first,
    );
    expect(tileCard.color, Colors.white);
  });
}
