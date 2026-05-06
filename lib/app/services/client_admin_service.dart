import 'dart:convert';

import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ClientAdminService extends GetxService {
  static UserSessionService get session => Get.find<UserSessionService>();

  final String baseUrl = dotenv.env['BASEURL']!;

  Future<ClientModel?> updateClient({
    required ClientModel client,
    required String name,
    required String email,
    required String phone,
    required DateTime expiresAt,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl/users/${client.id}');
    final userResponse = await http.get(url, headers: _buildHeaders());
    if (userResponse.statusCode != 200) return null;

    final Map<String, dynamic> userData = json.decode(userResponse.body);
    final expirationTime = _buildExpirationTime(expiresAt);

    userData['name'] = name.trim();
    userData['email'] = email.trim();
    userData['phone'] = phone.trim();
    userData['expirationTime'] = expirationTime.toUtc().toIso8601String();

    final passwordValue = password?.trim();
    if (passwordValue != null && passwordValue.isNotEmpty) {
      userData['password'] = passwordValue;
    }

    final attributes = Map<String, dynamic>.from(userData['attributes'] ?? {});
    attributes['expiresAt'] = _formatDateOnly(expiresAt);
    userData['attributes'] = attributes;

    final response = await http.put(
      url,
      headers: _buildHeaders(),
      body: json.encode(userData),
    );

    if (response.statusCode != 200) return null;

    return client.copyWith(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      expiresAt: DateTime(expiresAt.year, expiresAt.month, expiresAt.day),
    );
  }

  Future<Set<int>> getLinkedDeviceIds(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/permissions'), headers: _buildHeaders());
    if (response.statusCode != 200) return <int>{};

    final List data = json.decode(response.body);
    final deviceIds = <int>{};

    for (final permission in data) {
      if (_toInt(permission['userId']) != userId) continue;

      final deviceId = _toInt(permission['deviceId']);
      if (deviceId != null) {
        deviceIds.add(deviceId);
      }

      final devices = permission['devices'];
      if (devices is List) {
        for (final device in devices) {
          final id = device is Map ? _toInt(device['id']) : _toInt(device);
          if (id != null) {
            deviceIds.add(id);
          }
        }
      }
    }

    return deviceIds;
  }

  Future<bool> linkDevice({
    required int userId,
    required int deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/permissions'),
      headers: _buildHeaders(),
      body: json.encode({
        'userId': userId,
        'deviceId': deviceId,
      }),
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  Future<bool> unlinkDevice({
    required int userId,
    required int deviceId,
  }) async {
    final request = http.Request('DELETE', Uri.parse('$baseUrl/permissions'));
    request.headers.addAll(_buildHeaders());
    request.body = json.encode({
      'userId': userId,
      'deviceId': deviceId,
    });

    final response = await request.send();
    return response.statusCode >= 200 && response.statusCode < 300;
  }

  DateTime _buildExpirationTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  String _formatDateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (session.sessionId.value.isNotEmpty) {
      headers['Cookie'] = 'JSESSIONID=${session.sessionId.value}';
    }
    return headers;
  }
}
