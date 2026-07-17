// lib/core/services/traccar/traccar_websocket_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TraccarWebSocketService {
  WebSocketChannel? _channel;
  bool get isConnected => _channel != null;
  UserSessionService session = Get.find<UserSessionService>();

  /// Vários consumidores (Home, mapa, etc.) podem escutar o mesmo socket —
  /// cada `connect` só abre canal novo se ainda não houver um aberto.
  final List<void Function(Map<String, dynamic>)> _listeners = [];

  void connect({required void Function(Map<String, dynamic>) onData, void Function(dynamic error)? onError}) {
    if (!_listeners.contains(onData)) _listeners.add(onData);
    if (isConnected) return;

    final uri = _resolveUri(dotenv.env['SOCKET_URL']!);

    _channel = IOWebSocketChannel.connect(uri, headers: {HttpHeaders.cookieHeader: 'JSESSIONID=${session.sessionId.value}'});

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        for (final listener in List<void Function(Map<String, dynamic>)>.of(_listeners)) {
          listener(data);
        }
      },
      onError: onError,
      onDone: () {
        print('🔌 Traccar WebSocket fechado');
      },
    );
  }

  /// Uri.port resolve pra 0 quando o scheme é ws/wss sem porta explícita
  /// (o Dart só conhece porta padrão pra http/https) — sem isso o
  /// IOWebSocketChannel tenta conectar na porta 0 e a upgrade falha.
  Uri _resolveUri(String value) {
    final uri = Uri.parse(value);
    if (uri.hasPort) return uri;
    return uri.replace(port: uri.scheme == 'wss' ? 443 : 80);
  }

  /// Remove só o listener do chamador, sem derrubar o socket para os demais.
  void removeListener(void Function(Map<String, dynamic>) onData) {
    _listeners.remove(onData);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _listeners.clear();
  }
}
