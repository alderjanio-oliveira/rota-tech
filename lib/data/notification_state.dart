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
  final RxSet<int> mutedDeviceIds = <int>{}.obs;
  final NoticationConfigService _service = NoticationConfigService();

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

  Future<void> loadNotifications() async {
    final data = await AppNotificationStore().all();
    final muted = await AppNotificationStore().mutedDeviceAlerts();
    notifications.assignAll(data);
    mutedDeviceIds.assignAll(muted);
    unreadCount.value = data.where((notification) => !notification.read).length;
  }

  Future<void> markAllRead() async {
    await AppNotificationStore().markAllRead();
    await loadNotifications();
  }

  Future<void> clearNotifications() async {
    await AppNotificationStore().clear();
    await loadNotifications();
  }

  Future<void> removeNotification(String notificationId) async {
    await AppNotificationStore().remove(notificationId);
    await loadNotifications();
  }

  Future<void> removeActiveTripAlert(int deviceId) async {
    await AppNotificationStore().removeActiveTripAlert(deviceId);
  }

  Future<void> toggleMutedDevice(int deviceId) async {
    await AppNotificationStore().toggleMutedDevice(deviceId);
    await loadNotifications();
  }

  bool isDeviceMuted(int? deviceId) {
    if (deviceId == null) return false;
    return mutedDeviceIds.contains(deviceId);
  }
}
