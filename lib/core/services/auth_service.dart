import 'dart:convert';

import 'package:app_tracking/core/services/api_helper.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/core/utils/api.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final UserSessionService session;
  final ApiHelper apiHelper;

  AuthService({
    required this.session,
    required this.apiHelper,
  });
  Future<bool> login(String email, String password) async {
    try {
      final response = await apiHelper.post({'email': email, 'password': password}, Api().session);
      if (response == false) return false;
      if (response.statusCode != 200) return false;
      session.setUserEmail(email);
      return _buildSession(response);
    } catch (e) {
      return false;
    }
  }

  bool _buildSession(response) {
    final setCookie = response.headers['set-cookie'];
    session.setUserId(json.decode(response.body)['id']);
    session.isAdmin(json.decode(response.body)['administrator'] == true);
    session.setName(json.decode(response.body)['name']);
    if (setCookie != null) {
      final cookieParts = setCookie.split(';')[0].split('=');
      if (cookieParts.length == 2 && cookieParts[0] == 'JSESSIONID') {
        session.setSessionId(cookieParts[1]);
        return true;
      }
    }
    return false;
  }

  void logout() {
    session.setSessionId('');
    session.setUserEmail('');
    session.setName('');
    session.setAdmin(false);
    session.setUserId(0);
  }
}
