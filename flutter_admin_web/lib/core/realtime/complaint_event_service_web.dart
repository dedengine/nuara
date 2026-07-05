import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../network/api_client.dart';

class ComplaintEventService {
  ComplaintEventService(this.api);

  final ApiClient api;
  web.EventSource? _source;
  Timer? _retryTimer;
  bool _closed = false;
  void Function()? _onEvent;

  Future<void> start({required void Function() onEvent}) async {
    _closed = false;
    _onEvent = onEvent;
    await _connect();
  }

  Future<void> _connect() async {
    if (_closed) return;
    _source?.close();

    try {
      final response = await api.dio.post<Map<String, dynamic>>(
        '/api/admin/events/tiket',
      );
      if (_closed) return;

      final data = response.data?['data'];
      final ticket = data is Map<String, dynamic>
          ? data['tiket']?.toString()
          : null;
      if (ticket == null || ticket.isEmpty) {
        _scheduleReconnect();
        return;
      }

      final baseUri = Uri.parse(api.dio.options.baseUrl);
      final eventUri = baseUri
          .resolve('/api/admin/events')
          .replace(queryParameters: {'tiket': ticket});
      final source = web.EventSource(eventUri.toString());
      _source = source;
      source.onmessage = ((web.MessageEvent _) {
        _onEvent?.call();
      }).toJS;
      source.onerror = ((web.Event _) {
        source.close();
        if (identical(_source, source)) _source = null;
        _scheduleReconnect();
      }).toJS;
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_closed || _retryTimer?.isActive == true) return;
    _retryTimer = Timer(const Duration(seconds: 3), _connect);
  }

  void close() {
    _closed = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    _source?.close();
    _source = null;
    _onEvent = null;
  }
}
