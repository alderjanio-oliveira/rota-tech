import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:app_tracking/ui/controllers/billing_config_controller.dart';
import 'package:get/get.dart';

class BillingConfigBinding implements Bindings {
  @override
  void dependencies() {
    // BillingConfigService é registrado globalmente em MainBinding (outros
    // services também leem toleranceDays de lá, não só esta tela).
    Get.lazyPut(() => BillingConfigController(service: Get.find<BillingConfigService>()));
  }
}
