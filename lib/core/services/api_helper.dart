import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  static String get baseUrl => dotenv.env['BASEURL']!;
  static String get urlWs => dotenv.env['SOCKET_URL']!;

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
}
