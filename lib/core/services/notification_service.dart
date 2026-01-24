import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
  }

  Future<void> show({required String title, required String body, int id = 0}) async {
    const androidDetails = AndroidNotificationDetails(
      'traccar_events',
      'Eventos do Veículo',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'launch_background',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, details);
  }
}
