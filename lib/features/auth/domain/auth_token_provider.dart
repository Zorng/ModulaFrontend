import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the current access token in memory for attaching to HTTP requests.
///
/// This should be updated by the auth layer (e.g. on login / refresh) and
/// read by network clients such as Dio interceptors.
final authAccessTokenProvider =
    NotifierProvider<AuthAccessTokenNotifier, String?>(
      AuthAccessTokenNotifier.new,
    );

class AuthAccessTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setToken(String? token) {
    final trimmed = (token ?? '').trim();
    state = trimmed.isEmpty ? null : trimmed;
  }

  void clear() => state = null;
}
