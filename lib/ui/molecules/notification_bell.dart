import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/data/notification_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Get.find<NotificationState>();
    state.loadNotifications();

    return Obx(() {
      final count = state.unreadCount.value;

      return IconButton(
        tooltip: 'Notificações',
        onPressed: () {
          state.loadNotifications();
          Get.toNamed(Routes.NOTIFICATIONS);
        },
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : count.toString()),
          child: const Icon(Icons.notifications_outlined),
        ),
      );
    });
  }
}
