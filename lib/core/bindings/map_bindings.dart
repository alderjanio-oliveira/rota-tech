import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:get/get.dart';

class MapBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapCustomController>(
      () => MapCustomController(Get.find<TraccarService>(), Get.find<TraccarWebSocketService>()),
    ); // Certifique-se de que TraccarService já esteja registrado
  }
}
