import 'package:flutter_dotenv/flutter_dotenv.dart';

String baseUrl = dotenv.env['BASEURL']!;
String urlWs = dotenv.env['SOCKET_URL']!;

class Api {
  String users = '$baseUrl/users';
  String session = '$baseUrl/session';
  String devices = '$baseUrl/devices';
  String makeCommands = '$baseUrl/commands';
  String sendCommand = '$baseUrl/commands/send';
  String positions(deviceId) => '$baseUrl/positions?deviceId=$deviceId';
  String renewUser(session) => '$baseUrl/users/${session.userId.value}';
}
