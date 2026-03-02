import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/ui/controllers/warnings/warning_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService({FlutterLocalNotificationsPlugin? plugin}) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint("CLICOU NA NOTIFICAÇÃO 🚀");
        debugPrint("Payload: ${response.payload}");

        final payload = response.payload;
        if (payload != null) {
          Get.put(() => WarningController());
          Get.find<WarningController>().dispose();
          Get.toNamed(Routes.TRIP_DETAILS, arguments: payload);
        }
      },
    );
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

  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _plugin.getNotificationAppLaunchDetails();
  }
}
