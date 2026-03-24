import 'dart:async';
import 'dart:js_interop';

import 'package:modular_pos/features/notification/data/operational_notification_sse_parser.dart';
import 'package:modular_pos/features/notification/data/operational_notification_stream_contract.dart';
import 'package:web/web.dart' as html;

OperationalNotificationStreamClient
createPlatformOperationalNotificationStreamClient({
  required String baseUrl,
  required String prefix,
}) {
  return _WebOperationalNotificationStreamClient(
    baseUrl: baseUrl,
    prefix: prefix,
  );
}

class _WebOperationalNotificationStreamClient
    implements OperationalNotificationStreamClient {
  _WebOperationalNotificationStreamClient({
    required String baseUrl,
    required String prefix,
  }) : _streamUrl = _buildStreamUrl(baseUrl: baseUrl, prefix: prefix);

  final String _streamUrl;

  @override
  bool get isSupported => true;

  @override
  Future<OperationalNotificationStreamConnection> connect({
    required String accessToken,
  }) async {
    final abortController = html.AbortController();
    final eventsController =
        StreamController<OperationalNotificationRealtimeEvent>.broadcast();
    final parser = OperationalNotificationSseParser();
    final readerCompleter = Completer<html.ReadableStreamDefaultReader>();

    unawaited(
      _pumpStream(
        accessToken: accessToken,
        abortController: abortController,
        eventsController: eventsController,
        parser: parser,
        readerCompleter: readerCompleter,
      ),
    );

    return _WebOperationalNotificationStreamConnection(
      eventsController: eventsController,
      abortController: abortController,
      readerCompleter: readerCompleter,
    );
  }

  Future<void> _pumpStream({
    required String accessToken,
    required html.AbortController abortController,
    required StreamController<OperationalNotificationRealtimeEvent>
    eventsController,
    required OperationalNotificationSseParser parser,
    required Completer<html.ReadableStreamDefaultReader> readerCompleter,
  }) async {
    try {
      final headers = html.Headers()
        ..set('Accept', 'text/event-stream')
        ..set('Authorization', 'Bearer ${accessToken.trim()}');

      final response = await html.window
          .fetch(
            _streamUrl.toJS,
            html.RequestInit(
              method: 'GET',
              headers: headers,
              mode: 'cors',
              cache: 'no-store',
              credentials: 'same-origin',
              signal: abortController.signal,
            ),
          )
          .toDart;

      if (!response.ok) {
        throw StateError(
          'Notification stream failed: ${response.status} ${response.statusText}',
        );
      }

      final body = response.body;
      if (body == null) {
        throw StateError('Notification stream body is unavailable.');
      }

      final reader = html.ReadableStreamDefaultReader(body);
      readerCompleter.complete(reader);

      final decoder = html.TextDecoder();
      while (true) {
        final result = await reader.read().toDart;
        if (result.done) break;

        final value = result.value;
        if (value == null) continue;
        final chunk = decoder.decode(
          value as html.AllowSharedBufferSource,
          html.TextDecodeOptions(stream: true),
        );
        for (final event in parser.addChunk(chunk)) {
          if (eventsController.isClosed) break;
          eventsController.add(event);
        }
      }

      for (final event in parser.close()) {
        if (eventsController.isClosed) break;
        eventsController.add(event);
      }
    } catch (error, stackTrace) {
      if (_isAbortError(error)) {
        if (!eventsController.isClosed) {
          await eventsController.close();
        }
        return;
      }
      if (!eventsController.isClosed) {
        eventsController.addError(error, stackTrace);
        await eventsController.close();
      }
      return;
    }

    if (!eventsController.isClosed) {
      await eventsController.close();
    }
  }

  static String _buildStreamUrl({
    required String baseUrl,
    required String prefix,
  }) {
    final normalizedBaseUrl = baseUrl.trim().endsWith('/')
        ? baseUrl.trim()
        : '${baseUrl.trim()}/';
    final normalizedPrefix = prefix.trim().replaceFirst(RegExp(r'^/'), '');
    final path = normalizedPrefix.endsWith('/stream')
        ? normalizedPrefix
        : '$normalizedPrefix/stream';
    return Uri.parse(normalizedBaseUrl).resolve(path).toString();
  }

  bool _isAbortError(Object error) {
    return error.toString().contains('AbortError');
  }
}

class _WebOperationalNotificationStreamConnection
    implements OperationalNotificationStreamConnection {
  _WebOperationalNotificationStreamConnection({
    required StreamController<OperationalNotificationRealtimeEvent>
    eventsController,
    required html.AbortController abortController,
    required Completer<html.ReadableStreamDefaultReader> readerCompleter,
  }) : _eventsController = eventsController,
       _abortController = abortController,
       _readerCompleter = readerCompleter;

  final StreamController<OperationalNotificationRealtimeEvent>
  _eventsController;
  final html.AbortController _abortController;
  final Completer<html.ReadableStreamDefaultReader> _readerCompleter;

  @override
  Stream<OperationalNotificationRealtimeEvent> get events =>
      _eventsController.stream;

  @override
  Future<void> close() async {
    _abortController.abort();
    if (_readerCompleter.isCompleted) {
      final reader = await _readerCompleter.future;
      try {
        await reader.cancel().toDart;
      } catch (_) {}
      try {
        reader.releaseLock();
      } catch (_) {}
    }
    if (!_eventsController.isClosed) {
      await _eventsController.close();
    }
  }
}
