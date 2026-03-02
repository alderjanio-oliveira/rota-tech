import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:app_tracking/ui/model/billing_config_model.dart';
import 'package:get/get.dart';

class BillingConfigController extends GetxController {
  final BillingConfigService service;

  BillingConfigController({required this.service});

  final companyName = ''.obs;
  final pixKey = ''.obs;
  final pixKeyType = PixKeyType.cpf.obs;
  final price = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final config = service.loadBillingConfig();
    if (config != null) {
      companyName.value = config.companyName;
      pixKey.value = config.pixKey;
      pixKeyType.value = config.pixKeyType;
    }
  }

  void save() {
    service.saveBillingConfig(
      BillingConfig(companyName: companyName.value, pixKey: pixKey.value, pixKeyType: pixKeyType.value, price: price.value),
    );
    Get.snackbar('Sucesso', 'Configurações salvas');
  }
}
