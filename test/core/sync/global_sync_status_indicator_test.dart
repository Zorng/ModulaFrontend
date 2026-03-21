import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/sync/global_sync_status.dart';
import 'package:modular_pos/core/widgets/sync/global_sync_status_indicator.dart';

void main() {
  testWidgets('GlobalSyncStatusPill renders the current status label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlobalSyncStatusPill(
              status: GlobalSyncStatus(
                kind: GlobalSyncStatusKind.syncing,
                label: 'Syncing',
                detail: 'Refreshing workspace data.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Syncing'), findsOneWidget);
    expect(find.byIcon(Icons.sync_outlined), findsOneWidget);
  });

  testWidgets('GlobalSyncStatusIndicator reads shared provider state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalSyncStatusProvider.overrideWithValue(
            const GlobalSyncStatus(
              kind: GlobalSyncStatusKind.offline,
              label: 'Offline',
              detail: 'Showing cached data when available.',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: GlobalSyncStatusIndicator())),
        ),
      ),
    );

    expect(find.text('Offline'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
  });
}
