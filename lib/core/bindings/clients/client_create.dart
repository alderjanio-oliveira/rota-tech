import 'package:app_tracking/app/services/client_admin_service.dart';
import 'package:app_tracking/ui/controllers/client_create_controller.dart';
import 'package:get/get.dart';

class ClientCreateBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ClientAdminService());
    Get.lazyPut(() => ClientCreateController(clientAdminService: Get.find()));
  }
}
