import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:modular_pos/core/bootstrap/google_maps_web_sdk_loader.dart';
import 'package:modular_pos/core/config/app_env.dart';
import 'package:modular_pos/core/hydration/context_scoped_runtime_resource.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modular_pos/app.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';
import 'package:modular_pos/features/cash_session/data/cash_session_sync_pull_consumer.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/core/sync/sync_pull_orchestrator.dart';
import 'package:modular_pos/features/menu/data/menu_sync_pull_consumer.dart';
import 'package:modular_pos/features/notification/data/operational_notification_runtime_resource.dart';
import 'package:modular_pos/features/policy/data/policy_sync_pull_consumer.dart';
import 'package:modular_pos/features/staff_attendance/data/attendance_sync_pull_consumer.dart';
import 'package:modular_pos/features/staff/data/staff_shift_sync_pull_consumer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web, prefer --dart-define and avoid asset fetch for .env.
  if (!kIsWeb) {
    await dotenv.load(fileName: '.env', isOptional: true);
  }
  if (kIsWeb) {
    await ensureGoogleMapsWebSdkLoaded(apiKey: AppEnv.googleMapsApiKey);
  }

  final prefs = await SharedPreferences.getInstance();
  final store = AuthSessionStore(prefs);
  final idempotencyStore = SharedPrefsIdempotencyKeyStore(prefs);
  final initialSession = await store.load();

  runApp(
    ProviderScope(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(initialSession),
        idempotencyKeyStoreProvider.overrideWithValue(idempotencyStore),
        contextScopedRuntimeResourcesProvider.overrideWith((ref) {
          return [ref.watch(operationalNotificationRuntimeResourceProvider)];
        }),
        syncPullConsumersProvider.overrideWith((ref) {
          return [
            ref.watch(policySyncPullConsumerProvider),
            ref.watch(cashSessionSyncPullConsumerProvider),
            ref.watch(menuSyncPullConsumerProvider),
            ref.watch(attendanceSyncPullConsumerProvider),
            ref.watch(staffShiftSyncPullConsumerProvider),
          ];
        }),
      ],
      child: const ModulaApp(),
    ),
  );
}
