import 'package:get/get.dart';

class UserSessionService extends GetxService {
  final RxBool isAdmin = true.obs;
  final RxString userEmail = ''.obs;
  final RxString name = ''.obs;
  final RxString sessionId = ''.obs;
  final RxInt userId = 0.obs;

  void setAdmin(bool value) {
    isAdmin.value = value;
  }

  void setUserEmail(String email) {
    userEmail.value = email;
  }

  void setName(String userName) {
    name.value = userName;
  }

  void setSessionId(String id) {
    sessionId.value = id;
  }

  void setUserId(int id) {
    userId.value = id;
  }
}
