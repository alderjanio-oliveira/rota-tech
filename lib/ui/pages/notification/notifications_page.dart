import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/data/notification_state.dart';
import 'package:app_tracking/ui/model/app_notification_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Get.find<NotificationState>();
    WidgetsBinding.instance.addPostFrameCallback((_) => state.markAllRead());

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            tooltip: 'Limpar',
            onPressed: state.clearNotifications,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Obx(() {
        if (state.notifications.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Nenhuma notificação registrada.'),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final notification = state.notifications[index];
            return _NotificationCard(notification: notification);
          },
        );
      }),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          child: Icon(_icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(notification.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(_subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _DetailRow(label: 'Mensagem', value: notification.body),
          if (notification.deviceName != null) _DetailRow(label: 'Veículo', value: notification.deviceName!),
          if (notification.totalKm != null) _DetailRow(label: 'Km total', value: '${notification.totalKm!.toStringAsFixed(2)} km'),
          if (notification.tripKm != null) _DetailRow(label: 'Km rodado', value: '${notification.tripKm!.toStringAsFixed(2)} km'),
          if (notification.targetKm != null) _DetailRow(label: 'Meta', value: '${notification.targetKm!.toStringAsFixed(2)} km'),
          if (notification.remainingKm != null) _DetailRow(label: 'Faltam', value: '${notification.remainingKm!.toStringAsFixed(2)} km'),
          _DetailRow(label: 'Registrada em', value: _formatDate(notification.createdAt)),
        ],
      ),
    );
  }

  IconData get _icon {
    if (notification.type == 'charge') return Icons.power_off;
    return Icons.speed;
  }

  String get _subtitle {
    if (notification.deviceName == null) return _formatDate(notification.createdAt);
    return '${notification.deviceName} - ${_formatDate(notification.createdAt)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
