import 'package:app_tracking/core/services/notication_config_service.dart';
import 'package:app_tracking/data/notification_state.dart';
import 'package:app_tracking/ui/model/notification_config_model.dart';
import 'package:get/get.dart';

class NotificationConfigController extends GetxController {
  NotificationConfigController();
  final NoticationConfigService _service = NoticationConfigService();
  RxBool isEnabled = false.obs;
  RxBool ignitionAlert = false.obs;
  RxBool chargeAlert = false.obs;
  RxBool tripAlert = false.obs;
  final NotificationState _notificationState = Get.find<NotificationState>();

  @override
  void onInit() {
    super.onInit();
    loadConfig();
  }

  void loadConfig() {
    isEnabled.value = _notificationState.isEnabled.value;
    ignitionAlert.value = _notificationState.ignitionAlert.value;
    chargeAlert.value = _notificationState.chargeAlert.value;
    tripAlert.value = _notificationState.tripAlert.value;
  }

  void allOptions(bool value) {
    isEnabled.value = value;
    ignitionAlert.value = value;
    chargeAlert.value = value;
    tripAlert.value = value;
  }

  void saveConfig() {
    final notificationConfig = NotificationConfigModel(
      isEnabled: isEnabled.value,
      ignitionAlert: ignitionAlert.value,
      chargeAlert: chargeAlert.value,
      tripAlert: tripAlert.value,
    );
    _service.saveNotificationConfig(notificationConfig.toJson());
    _notificationState.load();
    loadConfig();
  }
}
