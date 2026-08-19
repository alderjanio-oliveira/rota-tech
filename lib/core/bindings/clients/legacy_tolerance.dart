import 'package:app_tracking/app/services/client_admin_service.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:app_tracking/ui/controllers/legacy_tolerance_controller.dart';
import 'package:get/get.dart';

class LegacyToleranceBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ClientAdminService());
    Get.lazyPut(
      () => LegacyToleranceController(
        traccarService: Get.find<TraccarService>(),
        clientAdminService: Get.find(),
        billingConfigService: Get.find<BillingConfigService>(),
      ),
    );
  }
}
