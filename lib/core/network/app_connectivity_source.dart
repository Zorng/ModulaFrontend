import 'package:modular_pos/core/network/app_connectivity_contract.dart';
import 'package:modular_pos/core/network/app_connectivity_source_stub.dart'
    if (dart.library.js_interop) 'package:modular_pos/core/network/app_connectivity_source_web.dart';

AppConnectivitySource createAppConnectivitySource() {
  return createPlatformConnectivitySource();
}
