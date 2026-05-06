import 'package:app_tracking/app/services/client_admin_service.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/controllers/clients_details_controller.dart';
import 'package:get/get.dart';

class ClientsDetailsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientsDetailsController>(
      () => ClientsDetailsController(
        vehicle: Get.find<VehicleState>(),
        clientAdminService: Get.put(ClientAdminService()),
      ),
    );
  }
}
