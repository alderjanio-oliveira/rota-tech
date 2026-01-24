import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:app_tracking/ui/controllers/vehicles/vehicles_detail_controller.dart';
import 'package:get/get.dart';

class VehicleDetailsBindings implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MapCustomController>(() => MapCustomController(Get.find()));
    Get.lazyPut<VehicleDetailsController>(
      () => VehicleDetailsController(
        traccarService: Get.find<TraccarService>(),
        deviceId: Get.arguments,
      ),
    ); // Assuming TraccarService is already registered
  }
}
