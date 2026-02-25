// lib/core/services/traccar/traccar_service.dart
import 'dart:convert';
import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/ui/models/daily_distance.dart';
import 'package:app_tracking/ui/models/daily_km_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class TraccarService extends GetxService {
  static TraccarService get to => Get.find();
  static UserSessionService get session => UserSessionService.to;

  final String baseUrl = "http://167.99.126.116:8082/api";
  final String urlWs = "ws://167.99.126.116:8082/api/socket";
  final RxString _jsessionId = RxString('');
  String? get jsessionId => _jsessionId.value.isEmpty ? null : _jsessionId.value;
  final RxInt _userId = RxInt(0);
  String? get userId => _userId.value == 0 ? null : _userId.value.toString();

  TraccarService();

  Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('$baseUrl/session');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'email': email, 'password': password},
      );

      if (response.statusCode != 200) return false;
      final setCookie = response.headers['set-cookie'];
      _userId.value = json.decode(response.body)['id'];
      session.isAdmin(json.decode(response.body)['administrator'] == true);
      session.setUserEmail(email);
      session.setName(json.decode(response.body)['name']);
      if (setCookie != null) {
        final cookieParts = setCookie.split(';')[0].split('=');
        if (cookieParts.length == 2 && cookieParts[0] == 'JSESSIONID') {
          _jsessionId.value = cookieParts[1];
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getDevices() async {
    final url = Uri.parse('$baseUrl/devices?userId=$userId');
    final response = await http.get(url, headers: _buildHeaders());

    if (response.statusCode == 200) {
      try {
        json.decode(response.body);
      } catch (e) {
        throw Exception('Resposta inesperada ao buscar dispositivos: ${response.body}');
      }
      print(json.decode(response.body));
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load devices: ${response.statusCode}');
    }
  }

  Future<Map?> getPositions(int deviceId) async {
    final url = Uri.parse('$baseUrl/positions?deviceId=$deviceId');
    final response = await http.get(url, headers: _buildHeaders());
    if (response.statusCode != 200) return null;
    final data = json.decode(response.body);
    if (data.isEmpty) return null;
    return data[0];
  }

  Future<Map<String, dynamic>?> getLastPosition(int deviceId) async {
    final url = Uri.parse("$baseUrl/reports/last?deviceId=$deviceId");

    final response = await http.get(url, headers: _buildHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // data é SEMPRE uma lista
      if (data is List && data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      }

      return null; // Nenhum registro encontrado
    } else {
      throw Exception("Erro ao buscar última posição (${response.statusCode}): ${response.body}");
    }
  }

  Future<Map<int, Map<String, dynamic>>> getLastPositions() async {
    final response = await http.get(Uri.parse('$baseUrl/positions'), headers: _buildHeaders());

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar posições');
    }

    final List list = json.decode(response.body);

    return {for (var p in list) p['deviceId']: p};
  }

  Future<List<dynamic>> getAllPositions() async {
    final url = Uri.parse('$baseUrl/positions');
    final response = await http.get(url, headers: _buildHeaders());

    if (response.statusCode != 200) return [];
    return json.decode(response.body);
  }

  generateCommand(int deviceId, String command) async {
    final url = Uri.parse('$baseUrl/commands');

    final response = await http.post(
      url,
      headers: _buildHeaders(),
      body: json.encode({'deviceId': deviceId, 'type': command, 'description': ''}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      return null;
    }
  }

  Future<bool> sendCommand(int deviceId, String command) async {
    // 1) gerar
    final commandData = await generateCommand(deviceId, command);
    if (commandData == null) return false;

    // 2) enviar
    final sendUrl = Uri.parse('$baseUrl/commands/send');

    final sendResponse = await http.post(
      sendUrl,
      headers: _buildHeaders(),
      body: json.encode({'id': commandData['id'], 'deviceId': deviceId}),
    );

    print("SEND: ${sendResponse.statusCode} -> ${sendResponse.body}");

    return sendResponse.statusCode == 200;
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (jsessionId != null) {
      headers['Cookie'] = 'JSESSIONID=$jsessionId';
    }
    return headers;
  }

  void logout() {
    _jsessionId.value = '';
  }

  Future<double?> getDailyDistance({required int deviceId, required DateTime day}) async {
    final from = DateTime(day.year, day.month, day.day).toUtc().toIso8601String();

    final to = DateTime(day.year, day.month, day.day, 23, 59, 59).toUtc().toIso8601String();

    final url = Uri.parse(
      '$baseUrl/reports/summary'
      '?deviceId=$deviceId'
      '&from=$from'
      '&to=$to',
    );

    final response = await http.get(url, headers: _buildHeaders());

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);

    if (data.isEmpty) return 0;

    final meters = data[0]['distance'] ?? 0;

    /// Converte para km com duas casas (caso deseje)
    return meters / 1000;
  }

  Future<List<DailyKm>> getDistanceByPeriod({required int deviceId, required DateTime from, required DateTime to}) async {
    final uri = Uri.parse(
      '$baseUrl/reports/summary'
      '?deviceId=$deviceId'
      '&from=${from.toUtc().toIso8601String()}'
      '&to=${to.toUtc().toIso8601String()}',
    );

    final response = await http.get(uri, headers: _buildHeaders());

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar relatório');
    }

    final List data = jsonDecode(response.body);

    return data.map((e) {
      return DailyKm(
        date: DateTime.parse(e['date']),
        km: (e['distance'] ?? 0) / 1000, // metros → km
      );
    }).toList();
  }

  Future<List<DailyDistance>> getDistanceByDay({required int deviceId, required DateTime from, required DateTime to}) async {
    final adjustedTo = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final uri = Uri.parse(
      '$baseUrl/reports/route'
      '?deviceId=$deviceId'
      '&from=${from.toUtc().toIso8601String()}'
      '&to=${adjustedTo.toUtc().toIso8601String()}',
    );

    final response = await http.get(uri, headers: _buildHeaders());
    if (response.statusCode != 200) return [];

    final List data = json.decode(response.body);

    final Map<String, List<double>> dailyOdometers = {};

    for (final item in data) {
      final date = DateTime.parse(item['deviceTime']).toLocal();
      final dayKey = DateFormat('yyyy-MM-dd').format(date);

      final odometer = (item['attributes']?['totalDistance'] ?? 0) / 1000.0;

      dailyOdometers.putIfAbsent(dayKey, () => []);
      dailyOdometers[dayKey]!.add(odometer);
    }

    return dailyOdometers.entries.map((e) {
      final values = e.value;
      final km = values.isNotEmpty ? values.last - values.first : 0.0;

      return DailyDistance(day: DateTime.parse(e.key), km: km);
    }).toList()..sort((a, b) => a.day.compareTo(b.day));
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final url = Uri.parse('$baseUrl/users');

    final response = await http.get(url, headers: _buildHeaders());

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar clientes: ${response.statusCode}');
    }

    final List data = json.decode(response.body);
    print(data);

    /// Retorna SOMENTE clientes (remove admin)
    return data.where((u) => u['administrator'] != true).map<Map<String, dynamic>>((u) {
      final attributes = u['attributes'] ?? {};

      return {
        'id': u['id'],
        'name': u['name'],
        'email': u['email'],
        'phone': u['phone'],
        'contractStart': attributes['contractStart'],
        'expiresAt': u['expirationTime'],
        'notified': attributes['notified'] ?? false,
      };
    }).toList();
  }

  Future<bool> renewClientContract(ClientModel client) async {
    final newExpireDate = DateTime(client.expiresAt!.year, client.expiresAt!.month + 1, client.expiresAt!.day);

    final url = Uri.parse('$baseUrl/users/$userId');

    final response = await http.put(
      url,
      headers: _buildHeaders(),
      body: json.encode({
        'id': client.id,
        'email': client.email,
        'name': client.name,
        'expirationTime': newExpireDate.toIso8601String(),
        'attributes': {'expiresAt': newExpireDate.toIso8601String(), 'notified': false},
      }),
    );

    return response.statusCode == 200;
  }

  Future<bool> updateDeviceTrip({
    required DeviceModel device,
    required String tripKey, // "tripA" ou "tripB"
    required double offset,
    double? target,
    bool active = true,
  }) async {
    final getUrl = Uri.parse('$baseUrl/devices/${device.id}');

    // 1️⃣ Buscar device atual
    final getResponse = await http.get(getUrl, headers: _buildHeaders());

    if (getResponse.statusCode != 200) return false;

    final deviceData = json.decode(getResponse.body);

    Map<String, dynamic> attributes = Map<String, dynamic>.from(deviceData['attributes'] ?? {});

    // 2️⃣ Garantir estrutura trips
    Map<String, dynamic> trips = Map<String, dynamic>.from(attributes['trip'] ?? {});

    // 3️⃣ Atualizar trip específica
    trips = {'offset': offset, 'target': target, 'active': active, 'name': tripKey};

    attributes['trip'] = trips;

    // 4️⃣ Enviar update
    final putUrl = Uri.parse('$baseUrl/devices/${device.id}');

    final response = await http.put(
      putUrl,
      headers: _buildHeaders(),
      body: json.encode({'id': deviceData['id'], 'name': deviceData['name'], 'uniqueId': deviceData['uniqueId'], 'attributes': attributes}),
    );

    return response.statusCode == 200;
  }
}
