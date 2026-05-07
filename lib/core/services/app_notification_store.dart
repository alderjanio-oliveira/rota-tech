import 'dart:convert';

import 'package:app_tracking/ui/model/app_notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotificationStore {
  static const notificationsKey = 'app_notifications';
  static const activeTripAlertsKey = 'active_trip_alerts';

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

  Future<Set<int>> activeTripAlerts() async {
    final raw = await _prefs.getString(activeTripAlertsKey);
    if (raw == null || raw.isEmpty) return <int>{};

    final data = jsonDecode(raw) as List;
    return data.map((item) => int.tryParse(item.toString())).whereType<int>().toSet();
  }

  Future<void> saveActiveTripAlerts(Set<int> deviceIds) async {
    await _prefs.setString(activeTripAlertsKey, jsonEncode(deviceIds.toList()));
  }
}
