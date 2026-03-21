import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/network/app_connectivity_source.dart';

final appConnectivitySourceProvider = Provider<AppConnectivitySource>((ref) {
  final source = createAppConnectivitySource();
  ref.onDispose(source.dispose);
  return source;
});

class AppConnectivityStatusController extends Notifier<AppConnectivityStatus> {
  StreamSubscription<AppConnectivityStatus>? _subscription;

  @override
  AppConnectivityStatus build() {
    _subscription?.cancel();
    final source = ref.watch(appConnectivitySourceProvider);
    _subscription = source.onStatusChanged.listen((status) {
      if (status == state) return;
      state = status;
    });
    ref.onDispose(() async {
      await _subscription?.cancel();
      _subscription = null;
    });
    return source.initialStatus;
  }
}

final appConnectivityStatusProvider =
    NotifierProvider<AppConnectivityStatusController, AppConnectivityStatus>(
      AppConnectivityStatusController.new,
    );
