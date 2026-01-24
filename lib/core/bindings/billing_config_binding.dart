import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:app_tracking/ui/controllers/billing_config_controller.dart';
import 'package:get/get.dart';

class BillingConfigBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BillingConfigService());
    Get.lazyPut(() => BillingConfigController(service: Get.find<BillingConfigService>()));
  }
}
