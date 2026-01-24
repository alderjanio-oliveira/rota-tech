import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:get/get.dart';

class MapBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapCustomController>(
      () => MapCustomController(Get.find()),
    ); // Certifique-se de que TraccarService já esteja registrado
  }
}
