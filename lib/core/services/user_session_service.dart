import 'package:get/get.dart';

class UserSessionService extends GetxService {
  static UserSessionService get to => Get.find();

  final RxBool isAdmin = true.obs;
  final RxString userEmail = ''.obs;
  final RxString name = ''.obs;

  void setAdmin(bool value) {
    isAdmin.value = value;
  }

  void setUserEmail(String email) {
    userEmail.value = email;
  }

  void setName(String userName) {
    name.value = userName;
  }
}
