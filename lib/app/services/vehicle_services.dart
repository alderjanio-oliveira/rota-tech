import 'dart:convert';

import 'package:app_tracking/app/services/reverse_geocode_service.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class VehicleServices extends GetxService {
  final String baseUrl = dotenv.env['BASEURL']!;
  final UserSessionService session;
  final ReverseGeocodeService geocodeService;

  VehicleServices({
    required this.geocodeService,
    required this.session,
  });

  Future<List<dynamic>> getDevices() async {
    final url = Uri.parse('$baseUrl/devices?userId=${session.userId.value}');
    final response = await http.get(url, headers: _buildHeaders());

    if (response.statusCode == 200) {
      try {
        json.decode(response.body);
      } catch (e) {
        throw Exception('Resposta inesperada ao buscar dispositivos: ${response.body}');
      }
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load devices: ${response.statusCode}');
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

  Future<void> loadAddresses(List<DeviceModel> devicesList, Map<int, dynamic> positions) async {
    for (int i = 0; i < devicesList.length; i++) {
      final device = devicesList[i];
      final position = positions[device.id];

      if (position == null) continue;
      if (device.attributes.address != null && device.attributes.address!.isNotEmpty) continue;
      final lat = position['latitude'];
      final lon = position['longitude'];

      if (lat == null || lon == null) continue;

      final address = await geocodeService.getAddress(lat, lon);

      devicesList[i] = device.copyWith(attributes: device.attributes.copyWith(address: address));
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
    if (session.sessionId.value.isNotEmpty) {
      headers['Cookie'] = 'JSESSIONID=${session.sessionId.value}';
    }
    return headers;
  }
}
