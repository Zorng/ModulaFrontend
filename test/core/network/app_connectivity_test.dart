import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:modular_pos/core/network/app_connectivity.dart';
import 'package:modular_pos/core/network/app_connectivity_contract.dart';

import '../../test_utils/riverpod_test_utils.dart';

void main() {
  test('status provider starts from source initial status', () {
    final source = _TestAppConnectivitySource(AppConnectivityStatus.offline);
    final container = createTestContainer(
      overrides: [appConnectivitySourceProvider.overrideWithValue(source)],
    );

    expect(
      container.read(appConnectivityStatusProvider),
      AppConnectivityStatus.offline,
    );
  });

  test('status provider updates when source emits a new status', () async {
    final source = _TestAppConnectivitySource(AppConnectivityStatus.offline);
    final container = createTestContainer(
      overrides: [appConnectivitySourceProvider.overrideWithValue(source)],
    );

    expect(
      container.read(appConnectivityStatusProvider),
      AppConnectivityStatus.offline,
    );

    source.emit(AppConnectivityStatus.online);
    await Future<void>.delayed(Duration.zero);

    expect(
      container.read(appConnectivityStatusProvider),
      AppConnectivityStatus.online,
    );
  });
}

class _TestAppConnectivitySource implements AppConnectivitySource {
  _TestAppConnectivitySource(this.initialStatus);

  @override
  final AppConnectivityStatus initialStatus;

  final StreamController<AppConnectivityStatus> _controller =
      StreamController<AppConnectivityStatus>.broadcast();

  @override
  Stream<AppConnectivityStatus> get onStatusChanged => _controller.stream;

  void emit(AppConnectivityStatus status) {
    _controller.add(status);
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
