import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/notification_state.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/model/app_notification_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    final state = Get.find<NotificationState>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await state.loadNotifications();
      await state.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Get.find<NotificationState>();
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            tooltip: 'Limpar',
            onPressed: () => state.clearNotifications(),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => state.loadNotifications(),
            icon: const Icon(Icons.refresh),
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
            return _NotificationCard(
              notification: notification,
              state: state,
              onResetTrip: () => _confirmResetTrip(context, notification, state),
              onToggleMute: () => _toggleMute(notification, state),
              onSendOilMessage: () => _sendOilMessage(notification),
            );
          },
        );
      }),
    );
  }

  void _confirmResetTrip(BuildContext context, AppNotificationModel notification, NotificationState state) {
    final targetController = TextEditingController(text: (notification.targetKm ?? 1000).toStringAsFixed(0));

    Get.dialog(
      AlertDialog(
        title: const Text('Zerar quilometragem'),
        content: TextField(
          controller: targetController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nova meta em km',
            hintText: 'Ex: 1000',
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _resetTrip(notification, state, targetController.text);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetTrip(AppNotificationModel notification, NotificationState state, String targetText) async {
    var device = _findDevice(notification.deviceId);
    if (device == null) {
      await Get.find<VehicleState>().load();
      device = _findDevice(notification.deviceId);
    }
    if (device == null) {
      Get.snackbar('Veículo não encontrado', 'Não foi possível localizar o veículo carregado no app.');
      return;
    }

    final totalDistance = device.attributes.totalDistance;
    if (totalDistance == null) {
      Get.snackbar('Odômetro indisponível', 'O veículo ainda não possui total de km para zerar a meta.');
      return;
    }

    final target = double.tryParse(targetText.replaceAll(',', '.'));
    if (target == null || target <= 0) {
      Get.snackbar('Meta inválida', 'Informe uma meta maior que zero.');
      return;
    }

    final tripKey = device.attributes.trip?.name ?? 'tripA';
    final success = await Get.find<TraccarService>().updateDeviceTrip(
      device: device,
      tripKey: tripKey,
      offset: totalDistance,
      target: target,
    );

    if (!success) {
      Get.snackbar('Erro', 'Não foi possível zerar a quilometragem.');
      return;
    }

    await state.removeActiveTripAlert(device.id);
    await state.removeNotification(notification.id);
    await Get.find<VehicleState>().load();
    Get.snackbar('Sucesso', 'Quilometragem zerada e nova meta definida.');
  }

  Future<void> _toggleMute(AppNotificationModel notification, NotificationState state) async {
    final deviceId = notification.deviceId;
    if (deviceId == null) return;

    await state.toggleMutedDevice(deviceId);
    final muted = state.isDeviceMuted(deviceId);
    Get.snackbar(
      muted ? 'Notificações desativadas' : 'Notificações reativadas',
      muted ? 'Este veículo não vai mais gerar alertas para este usuário.' : 'Este veículo voltou a gerar alertas para este usuário.',
    );
  }

  Future<void> _sendOilMessage(AppNotificationModel notification) async {
    final deviceId = notification.deviceId;
    if (deviceId == null) {
      Get.snackbar('Veículo não encontrado', 'A notificação não possui veículo associado.');
      return;
    }

    final traccarService = Get.find<TraccarService>();
    final clientsData = await traccarService.getClients();
    final permissions = await traccarService.getDevicesPerUser();
    Map<String, dynamic>? permission;
    for (final item in permissions) {
      if (item['deviceId'] == deviceId) {
        permission = item;
        break;
      }
    }
    if (permission == null) {
      Get.snackbar('Cliente não encontrado', 'Não encontrei o cliente vinculado a este veículo.');
      return;
    }

    Map<String, dynamic>? clientData;
    for (final item in clientsData) {
      if (item['id'] == permission['userId']) {
        clientData = item;
        break;
      }
    }
    if (clientData == null) {
      Get.snackbar('Cliente não encontrado', 'Não encontrei os dados do cliente vinculado.');
      return;
    }

    final client = ClientModel.fromMap(clientData);
    final phone = client.phone?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (phone.isEmpty) {
      Get.snackbar('Telefone não encontrado', 'O cliente não possui telefone cadastrado.');
      return;
    }

    final message = _buildOilMessage(client, notification);
    final uri = Uri.parse('https://wa.me/55$phone?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Erro', 'Não foi possível abrir o WhatsApp.');
    }
  }

  String _buildOilMessage(ClientModel client, AppNotificationModel notification) {
    final km = notification.tripKm?.toStringAsFixed(0) ?? '1000';
    final vehicle = notification.deviceName ?? 'seu veículo';

    return '''
Olá, Sr(a). ${client.name}! Tudo bem?

Passando só para avisar com tranquilidade:

- O veículo $vehicle já rodou cerca de $km km desde a última marcação.
- Essa meta geralmente usamos como referência para troca de óleo, perto de 1000 km.
- Se estiver no seu planejamento de manutenção, pode ser um bom momento para verificar ou trocar o óleo.

Sem correria, é só um lembrete para ajudar no cuidado com o veículo.

Qualquer dúvida, estamos à disposição.
''';
  }

  DeviceModel? _findDevice(int? deviceId) {
    if (deviceId == null) return null;

    for (final device in Get.find<VehicleState>().list) {
      if (device.id == deviceId) return device;
    }

    return null;
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotificationModel notification;
  final NotificationState state;
  final VoidCallback onResetTrip;
  final VoidCallback onToggleMute;
  final VoidCallback onSendOilMessage;

  const _NotificationCard({
    required this.notification,
    required this.state,
    required this.onResetTrip,
    required this.onToggleMute,
    required this.onSendOilMessage,
  });

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
          if (_canManage)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onResetTrip,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Zerar e nova meta'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSendOilMessage,
                    icon: const Icon(Icons.message_outlined),
                    label: const Text('Mensagem óleo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onToggleMute,
                    icon: Icon(state.isDeviceMuted(notification.deviceId) ? Icons.notifications_active_outlined : Icons.notifications_off_outlined),
                    label: Text(state.isDeviceMuted(notification.deviceId) ? 'Reativar alertas' : 'Silenciar para mim'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool get _canManage {
    if (notification.type != 'trip') return false;
    if (!Get.isRegistered<UserSessionService>()) return false;
    return Get.find<UserSessionService>().isAdmin.value;
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
