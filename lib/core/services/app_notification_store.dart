import 'dart:convert';

import 'package:app_tracking/ui/model/app_notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotificationStore {
  static const notificationsKey = 'app_notifications';
  static const activeTripAlertsKey = 'active_trip_alerts';
  static const mutedDeviceAlertsKey = 'muted_device_alerts';

  final SharedPreferencesAsync _prefs;

  AppNotificationStore({SharedPreferencesAsync? prefs}) : _prefs = prefs ?? SharedPreferencesAsync();

  Future<List<AppNotificationModel>> all() async {
    final raw = await _prefs.getString(notificationsKey);
    if (raw == null || raw.isEmpty) return [];

    final data = jsonDecode(raw) as List;
    return data
        .map((item) => AppNotificationModel.fromJson(Map<String, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<int> unreadCount() async {
    final notifications = await all();
    return notifications.where((notification) => !notification.read).length;
  }

  Future<void> add(AppNotificationModel notification) async {
    final notifications = await all();
    notifications.removeWhere((item) => item.id == notification.id);
    notifications.insert(0, notification);
    await _prefs.setString(
      notificationsKey,
      jsonEncode(notifications.take(100).map((item) => item.toJson()).toList()),
    );
  }

  Future<void> markAllRead() async {
    final updated = (await all()).map((item) => item.copyWith(read: true)).toList();
    await _prefs.setString(
      notificationsKey,
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    await _prefs.setString(notificationsKey, jsonEncode([]));
  }

  Future<void> remove(String notificationId) async {
    final notifications = await all();
    notifications.removeWhere((item) => item.id == notificationId);
    await _prefs.setString(
      notificationsKey,
      jsonEncode(notifications.map((item) => item.toJson()).toList()),
    );
  }

  Future<Set<int>> activeTripAlerts() async {
    final raw = await _prefs.getString(activeTripAlertsKey);
    if (raw == null || raw.isEmpty) return <int>{};

    final data = jsonDecode(raw) as List;
    return data.map((item) => int.tryParse(item.toString())).whereType<int>().toSet();
  }

  Future<void> saveActiveTripAlerts(Set<int> deviceIds) async {
    await _prefs.setString(activeTripAlertsKey, jsonEncode(deviceIds.toList()));
  }

  Future<void> removeActiveTripAlert(int deviceId) async {
    final activeAlerts = await activeTripAlerts();
    activeAlerts.remove(deviceId);
    await saveActiveTripAlerts(activeAlerts);
  }

  Future<Set<int>> mutedDeviceAlerts() async {
    final raw = await _prefs.getString(mutedDeviceAlertsKey);
    if (raw == null || raw.isEmpty) return <int>{};

    final data = jsonDecode(raw) as List;
    return data.map((item) => int.tryParse(item.toString())).whereType<int>().toSet();
  }

  Future<void> saveMutedDeviceAlerts(Set<int> deviceIds) async {
    await _prefs.setString(mutedDeviceAlertsKey, jsonEncode(deviceIds.toList()));
  }

  Future<void> toggleMutedDevice(int deviceId) async {
    final mutedDevices = await mutedDeviceAlerts();
    if (mutedDevices.contains(deviceId)) {
      mutedDevices.remove(deviceId);
    } else {
      mutedDevices.add(deviceId);
    }
    await saveMutedDeviceAlerts(mutedDevices);
  }
}
