// lib/core/services/traccar/traccar_websocket_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TraccarWebSocketService {
  WebSocketChannel? _channel;
  bool get isConnected => _channel != null;
  UserSessionService session = Get.find<UserSessionService>();

  void connect({required void Function(Map<String, dynamic>) onData, void Function(dynamic error)? onError}) {
    final uri = Uri.parse('ws://167.99.126.116:8082/api/socket');

    _channel = IOWebSocketChannel.connect(uri, headers: {HttpHeaders.cookieHeader: 'JSESSIONID=${session.sessionId.value}'});

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
        print(data);
        print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
        onData(data);
      },
      onError: onError,
      onDone: () {
        print('🔌 Traccar WebSocket fechado');
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
  }
}
