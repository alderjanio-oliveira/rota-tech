import 'dart:convert';

import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  static String get baseUrl => dotenv.env['BASEURL']!;
  static String get urlWs => dotenv.env['SOCKET_URL']!;
  UserSessionService session;

  ApiHelper({required this.session});

  Future<dynamic> post(Map<String, String> body, String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );
      return response;
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> get(url) async {
    final uri = Uri.parse(url);
    final response = await http.get(uri, headers: _buildHeaders());
    return response;
  }

  Future<dynamic> put(Map<String, String> body, String url) async {
    final uri = Uri.parse(url);
    final response = await http.put(
      uri,
      headers: _buildHeaders(),
      body: body,
    );
    return response;
  }

  Future<dynamic> postJson(Map<String, dynamic> body, String url) async {
    final uri = Uri.parse(url);
    final response = await http.post(
      uri,
      headers: _buildHeaders(),
      body: jsonEncode(body),
    );
    return response;
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (session.sessionId.value.isNotEmpty) {
      headers['Cookie'] = 'JSESSIONID=${session.sessionId.value}';
    }
    return headers;
  }
}
