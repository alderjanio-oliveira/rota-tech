import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.savePendingNavigation();
}

class NotificationService {
  static const pendingNavigationKey = 'pending_notification_navigation';

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('CLICOU NA NOTIFICAÇÃO');
        debugPrint('Payload: ${response.payload}');

        savePendingNavigation();
        openPendingNavigation();
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static void savePendingNavigation() {
    GetStorage().write(pendingNavigationKey, Routes.NOTIFICATIONS);
  }

  static bool openPendingNavigation() {
    final route = consumePendingNavigation();
    if (route == null) return false;

    Future.microtask(() {
      if (Get.currentRoute == route) return;
      Get.toNamed(route);
    });
    return true;
  }

  static String? consumePendingNavigation() {
    final route = GetStorage().read<String>(pendingNavigationKey);
    if (route != null) {
      GetStorage().remove(pendingNavigationKey);
    }
    return route;
  }

  Future<void> show({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    final bigTextStyle = BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: 'Resumo de veículos',
    );

    final androidDetails = AndroidNotificationDetails(
      'traccar_events',
      'Eventos do Veículo',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: bigTextStyle,
    );

    final details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> requestPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _plugin.getNotificationAppLaunchDetails();
  }
}
