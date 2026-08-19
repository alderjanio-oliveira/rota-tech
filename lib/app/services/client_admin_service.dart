import 'dart:convert';

import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ClientAdminService extends GetxService {
  static UserSessionService get session => Get.find<UserSessionService>();
  static BillingConfigService get billingConfig => Get.find<BillingConfigService>();

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

  /// Migração temporária: empurra o bloqueio real (expirationTime) de um
  /// cliente já cadastrado em [toleranceDays] dias. NÃO mexe em
  /// attributes.expiresAt — vencimento, cobrança e juros continuam iguais.
  Future<bool> applyLegacyTolerance(ClientModel client, int toleranceDays) async {
    final url = Uri.parse('$baseUrl/users/${client.id}');
    final userResponse = await http.get(url, headers: _buildHeaders());
    if (userResponse.statusCode != 200) return false;

    final Map<String, dynamic> userData = json.decode(userResponse.body);

    final currentBlockDate = DateTime.tryParse(userData['expirationTime'] ?? '') ?? DateTime.now();
    userData['expirationTime'] = currentBlockDate.add(Duration(days: toleranceDays)).toUtc().toIso8601String();

    final attributes = Map<String, dynamic>.from(userData['attributes'] ?? {});
    attributes['legacyToleranceAppliedAt'] = DateTime.now().toIso8601String();
    userData['attributes'] = attributes;

    final response = await http.put(url, headers: _buildHeaders(), body: json.encode(userData));
    return response.statusCode == 200;
  }

  /// Cadastra um cliente novo. [expiresAt] é o primeiro vencimento (pra
  /// cobrança) — o bloqueio real (expirationTime) já é gravado com a
  /// tolerância somada, igual aos fluxos de editar/renovar.
  Future<ClientModel?> createClient({
    required String name,
    required String email,
    required String phone,
    required String password,
    required DateTime contractStart,
    required DateTime expiresAt,
  }) async {
    final url = Uri.parse('$baseUrl/users');

    final body = {
      'name': name.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'password': password,
      'expirationTime': _buildExpirationTime(expiresAt).toUtc().toIso8601String(),
      'attributes': {
        'contractStart': _formatDateOnly(contractStart),
        'expiresAt': _formatDateOnly(expiresAt),
        'notified': false,
      },
    };

    final response = await http.post(url, headers: _buildHeaders(), body: json.encode(body));
    if (response.statusCode != 200) return null;

    final created = json.decode(response.body);
    final createdAttributes = created['attributes'] ?? {};

    return ClientModel.fromMap({
      'id': created['id'],
      'name': created['name'],
      'email': created['email'],
      'phone': created['phone'],
      'contractStart': createdAttributes['contractStart'],
      'expiresAt': createdAttributes['expiresAt'],
      'notified': createdAttributes['notified'] ?? false,
    });
  }

  Future<List<DeviceModel>> getLinkedDevices(int userId) async {
    final url = Uri.parse('$baseUrl/devices?userId=$userId&excludeAttributes=true');
    final response = await http.get(url, headers: _buildHeaders());
    if (response.statusCode != 200) return <DeviceModel>[];

    final List data = json.decode(response.body);
    return data.map<DeviceModel>((item) => DeviceModel.fromJson(item as Map<String, dynamic>)).toList();
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

  int get _toleranceDays => billingConfig.loadBillingConfig()?.toleranceDays ?? 10;

  /// Data em que o Traccar realmente bloqueia o login — vencimento (usado
  /// pra cobrança/juros/mensagens) + tolerância. `attributes.expiresAt`
  /// continua sendo só [date], sem a tolerância.
  DateTime _buildExpirationTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59).add(Duration(days: _toleranceDays));
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
