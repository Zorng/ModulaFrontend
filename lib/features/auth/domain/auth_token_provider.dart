import 'package:flutter_riverpod/legacy.dart';

/// Holds the current access token in memory for attaching to HTTP requests.
///
/// This should be updated by the auth layer (e.g. on login / refresh) and
/// read by network clients such as Dio interceptors.
final authAccessTokenProvider = StateProvider<String?>((ref) => null);
