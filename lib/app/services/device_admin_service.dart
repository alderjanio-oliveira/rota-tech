import 'dart:convert';

import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class DeviceAdminService extends GetxService {
  static UserSessionService get session => Get.find<UserSessionService>();

  final String baseUrl = dotenv.env['BASEURL']!;

  /// Cadastra um dispositivo novo no Traccar. [imei] vira o `uniqueId`
  /// (identificador que o rastreador usa pra se conectar) e [phone] é o
  /// número do chip — os dois já são campos nativos do Device, sem precisar
  /// de atributo customizado.
  Future<DeviceCreateResult> createDevice({
    required String name,
    required String imei,
    required String phone,
  }) async {
    final url = Uri.parse('$baseUrl/devices');

    final body = {
      'name': name.trim(),
      'uniqueId': imei.trim(),
      'phone': phone.trim(),
    };

    final response = await http.post(url, headers: _buildHeaders(), body: json.encode(body));

    if (response.statusCode == 200) {
      final created = json.decode(response.body);
      return DeviceCreateResult.success(id: created['id'], name: created['name'], phone: created['phone'] ?? '');
    }

    // Erro genérico do Traccar sempre vem como 400 com o stack trace no
    // corpo — se mencionar "unique" é o índice único de uniqueId (IMEI
    // duplicado), senão é outro problema de validação.
    if (response.statusCode == 400 && response.body.toLowerCase().contains('unique')) {
      return DeviceCreateResult.failure('Já existe um dispositivo cadastrado com esse IMEI.');
    }

    return DeviceCreateResult.failure('Não foi possível cadastrar o dispositivo (${response.statusCode}).');
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (session.sessionId.value.isNotEmpty) {
      headers['Cookie'] = 'JSESSIONID=${session.sessionId.value}';
    }
    return headers;
  }
}

class DeviceCreateResult {
  final bool ok;
  final int? id;
  final String? name;
  final String? phone;
  final String? error;

  const DeviceCreateResult._({required this.ok, this.id, this.name, this.phone, this.error});

  factory DeviceCreateResult.success({required int id, required String name, required String phone}) {
    return DeviceCreateResult._(ok: true, id: id, name: name, phone: phone);
  }

  factory DeviceCreateResult.failure(String error) => DeviceCreateResult._(ok: false, error: error);
}
