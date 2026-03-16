import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:get/get.dart';

class AuthBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(traccarService: Get.find(), authService: Get.find()),
      fenix: true,
    );
  }
}
