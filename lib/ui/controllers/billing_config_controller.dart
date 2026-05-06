import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:app_tracking/ui/model/billing_config_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BillingConfigController extends GetxController {
  final BillingConfigService service;

  BillingConfigController({required this.service});

  final companyName = ''.obs;
  final pixKey = ''.obs;
  final pixKeyType = PixKeyType.cpf.obs;
  final price = 0.0.obs;
  final dailyInterestPercent = 1.5.obs;
  final clientInfoMessageController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final config = service.loadBillingConfig();
    if (config != null) {
      companyName.value = config.companyName;
      pixKey.value = config.pixKey;
      pixKeyType.value = config.pixKeyType;
      price.value = config.price;
      dailyInterestPercent.value = config.dailyInterestPercent;
      clientInfoMessageController.text = config.clientInfoMessage;
    } else {
      clientInfoMessageController.text = BillingConfig.defaultClientInfoMessage;
    }
  }

  @override
  void onClose() {
    clientInfoMessageController.dispose();
    super.onClose();
  }

  void save() {
    service.saveBillingConfig(
      BillingConfig(
        companyName: companyName.value,
        pixKey: pixKey.value,
        pixKeyType: pixKeyType.value,
        price: price.value,
        dailyInterestPercent: dailyInterestPercent.value,
        clientInfoMessage: clientInfoMessageController.text,
      ),
    );
    Get.snackbar('Sucesso', 'Configurações salvas');
  }

  void resetClientInfoMessage() {
    clientInfoMessageController.text = BillingConfig.defaultClientInfoMessage;
    Get.snackbar('Mensagem restaurada', 'A mensagem padrão foi restaurada.');
  }
}
