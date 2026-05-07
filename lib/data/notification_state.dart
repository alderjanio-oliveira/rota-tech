import 'package:app_tracking/core/services/app_notification_store.dart';
import 'package:app_tracking/core/services/notication_config_service.dart';
import 'package:app_tracking/ui/model/app_notification_model.dart';
import 'package:app_tracking/ui/model/notification_config_model.dart';
import 'package:get/get.dart';

class NotificationState {
  RxBool isEnabled = false.obs;
  RxBool ignitionAlert = false.obs;
  RxBool chargeAlert = false.obs;
  RxBool tripAlert = false.obs;
  final RxList<AppNotificationModel> notifications = <AppNotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final NoticationConfigService _service = NoticationConfigService();
  final AppNotificationStore _notificationStore = AppNotificationStore();

  NotificationState() {
    ever(isEnabled, (value) => print("Notification enabled: $value"));
    ever(ignitionAlert, (value) => print("Ignition alert: $value"));
    ever(chargeAlert, (value) => print("Charge alert: $value"));
    load();
    loadNotifications();
  }

  void load() {
    final configJson = _service.getNotificationConfig();
    if (configJson != null) {
      final config = NotificationConfigModel.fromJson(Map<String, dynamic>.from(configJson));
      isEnabled.value = config.isEnabled;
      ignitionAlert.value = config.ignitionAlert;
      chargeAlert.value = config.chargeAlert;
      tripAlert.value = config.tripAlert;
    }
  }

  void loadNotifications() {
    final data = _notificationStore.all();
    notifications.assignAll(data);
    unreadCount.value = data.where((notification) => !notification.read).length;
  }

  void markAllRead() {
    _notificationStore.markAllRead();
    loadNotifications();
  }

  void clearNotifications() {
    _notificationStore.clear();
    loadNotifications();
  }
}
