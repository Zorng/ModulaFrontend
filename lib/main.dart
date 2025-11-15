import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:modular_pos/app.dart';
import 'package:modular_pos/features/auth/data/auth_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
