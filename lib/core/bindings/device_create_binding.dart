import 'package:app_tracking/app/services/device_admin_service.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/controllers/device_create_controller.dart';
import 'package:get/get.dart';

class DeviceCreateBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DeviceAdminService());
    Get.lazyPut(() => DeviceCreateController(deviceAdminService: Get.find(), vehicleState: Get.find<VehicleState>()));
  }
}
