import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/config/map_tracking_config.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:app_tracking/ui/controllers/vehicles/vehicles_detail_controller.dart';
import 'package:get/get.dart';

class VehicleDetailsBindings implements Bindings {
  MapTrackingConfig mapTrackingConfig = MapTrackingConfig(mode: TrailMode.byPoints, value: 200);
  @override
  void dependencies() {
    Get.lazyPut<MapCustomController>(
      () => MapCustomController(Get.find<TraccarService>(), Get.find<TraccarWebSocketService>(), mapTrackingConfig, Get.find<VehicleState>()),
    ); // Certifique-se de que TraccarService já esteja registrado
    Get.lazyPut<VehicleDetailsController>(
      () => VehicleDetailsController(traccarService: Get.find<TraccarService>(), device: Get.arguments, vehicleState: Get.find<VehicleState>()),
    ); // Assuming TraccarService is already registered
  }
}
