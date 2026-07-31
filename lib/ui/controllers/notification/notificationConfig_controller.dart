import 'package:app_tracking/core/services/notication_config_service.dart';
import 'package:app_tracking/data/notification_state.dart';
import 'package:app_tracking/ui/model/notification_config_model.dart';
import 'package:get/get.dart';

class NotificationConfigController extends GetxController {
  NotificationConfigController();
  final NoticationConfigService _service = NoticationConfigService();

  /// Chave geral — quando desligada, nenhum alerta é enviado, independente
  /// dos toggles abaixo (eles continuam guardando a preferência do usuário).
  final RxBool isEnabled = false.obs;

  final RxBool chargeAlert = false.obs;
  final RxBool tripAlert = false.obs;

  final NotificationState _notificationState = Get.find<NotificationState>();

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  void loadConfig() {
    isEnabled.value = _notificationState.isEnabled.value;
    chargeAlert.value = _notificationState.chargeAlert.value;
    tripAlert.value = _notificationState.tripAlert.value;
  }

  void setEnabled(bool value) => isEnabled.value = value;
  void setChargeAlert(bool value) => chargeAlert.value = value;
  void setTripAlert(bool value) => tripAlert.value = value;

  void saveConfig() {
    final notificationConfig = NotificationConfigModel(
      isEnabled: isEnabled.value,
      // Ainda sem tela própria — preserva o que já estava salvo.
      ignitionAlert: _notificationState.ignitionAlert.value,
      chargeAlert: chargeAlert.value,
      tripAlert: tripAlert.value,
    );
    _service.saveNotificationConfig(notificationConfig.toJson());
    _notificationState.load();
    loadConfig();
    Get.snackbar('Salvo', 'Preferências de notificação atualizadas.');
  }
}
