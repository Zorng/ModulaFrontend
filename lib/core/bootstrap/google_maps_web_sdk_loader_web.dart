import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as html;

Completer<void>? _googleMapsLoadCompleter;

Future<void> ensureGoogleMapsWebSdkLoaded({required String apiKey}) {
  if (apiKey.trim().isEmpty) return Future<void>.value();

  final existingLoad = _googleMapsLoadCompleter;
  if (existingLoad != null) return existingLoad.future;

  final completer = Completer<void>();
  _googleMapsLoadCompleter = completer;

  final script = html.HTMLScriptElement()
    ..async = true
    ..defer = true
    ..src =
        'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(apiKey.trim())}';
  script.setAttribute('data-google-maps-sdk', 'true');

  script.addEventListener(
    'load',
    ((JSAny? _) {
      if (!completer.isCompleted) completer.complete();
      return true;
    }).toJS,
  );
  script.addEventListener(
    'error',
    ((JSAny? _) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Failed to load Google Maps JavaScript SDK.'),
        );
      }
      return true;
    }).toJS,
  );

  final mountNode = html.document.head ?? html.document.body;
  if (mountNode == null) {
    completer.completeError(
      StateError('Document head/body is unavailable for Google Maps SDK load.'),
    );
    return completer.future;
  }

  mountNode.append(script);
  return completer.future;
}
