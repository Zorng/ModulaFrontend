import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modular_pos/app.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables; allow missing file in dev/CI.
  await dotenv.load(fileName: '.env', isOptional: true);

  final prefs = await SharedPreferences.getInstance();
  final store = AuthSessionStore(prefs);
  final initialSession = await store.load();

  runApp(
    ProviderScope(
      overrides: [
        authSessionStoreProvider.overrideWithValue(store),
        initialAuthSessionProvider.overrideWithValue(initialSession),
      ],
      child: const ModulaApp(),
    ),
  );
}
