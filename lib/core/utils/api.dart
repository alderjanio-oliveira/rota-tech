import 'package:flutter_dotenv/flutter_dotenv.dart';

String baseUrl = dotenv.env['BASEURL']!;
String urlWs = dotenv.env['SOCKET_URL']!;

class Api {
  String session = '$baseUrl/session';
}
