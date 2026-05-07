import 'package:app_tracking/ui/model/app_notification_model.dart';
import 'package:get_storage/get_storage.dart';

class AppNotificationStore {
  static const notificationsKey = 'app_notifications';
  static const activeTripAlertsKey = 'active_trip_alerts';

  final GetStorage _box;

  AppNotificationStore({GetStorage? box}) : _box = box ?? GetStorage();

  List<AppNotificationModel> all() {
    final data = _box.read<List>(notificationsKey) ?? [];
    return data
        .map((item) => AppNotificationModel.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int unreadCount() {
    return all().where((notification) => !notification.read).length;
  }

  void add(AppNotificationModel notification) {
    final notifications = all();
    notifications.removeWhere((item) => item.id == notification.id);
    notifications.insert(0, notification);
    _box.write(notificationsKey, notifications.take(100).map((item) => item.toJson()).toList());
  }

  void markAllRead() {
    final updated = all().map((item) => item.copyWith(read: true)).toList();
    _box.write(notificationsKey, updated.map((item) => item.toJson()).toList());
  }

  void clear() {
    _box.write(notificationsKey, []);
  }

  Set<int> activeTripAlerts() {
    final data = _box.read<List>(activeTripAlertsKey) ?? [];
    return data.map((item) => int.tryParse(item.toString())).whereType<int>().toSet();
  }

  void saveActiveTripAlerts(Set<int> deviceIds) {
    _box.write(activeTripAlertsKey, deviceIds.toList());
  }
}
