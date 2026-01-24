import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:get/get.dart';

class AuthBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TraccarService>(() => TraccarService());
    Get.lazyPut<AuthController>(() => AuthController(Get.find()));
  }
}
