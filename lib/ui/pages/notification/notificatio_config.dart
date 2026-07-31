import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/ui/atoms/button/primary.dart';
import 'package:app_tracking/ui/controllers/notification/notificationConfig_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationConfigPage extends GetView<NotificationConfigController> {
  const NotificationConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Configurações de Notificação')),
      body: Obx(() {
        final enabled = controller.isEnabled.value;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _MasterSwitchCard(value: enabled, onChanged: controller.setEnabled),
            const SizedBox(height: 24),
            Text('Tipos de alerta', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Escolha quais eventos devem gerar notificações no app.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _AlertTile(
              icon: Icons.battery_alert_outlined,
              title: 'Bateria desconectada',
              description: 'Avisa quando o rastreador perder alimentação da bateria do veículo.',
              value: controller.chargeAlert.value,
              enabled: enabled,
              onChanged: controller.setChargeAlert,
            ),
            const SizedBox(height: 10),
            _AlertTile(
              icon: Icons.route_outlined,
              title: 'Meta de quilometragem',
              description: 'Avisa quando um veículo atingir a meta configurada na Trip A.',
              value: controller.tripAlert.value,
              enabled: enabled,
              onChanged: controller.setTripAlert,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'O sino no veículo e o aviso nos detalhes aparecem sempre que a meta for batida, mesmo com as notificações desligadas.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(text: 'Salvar', onPressed: controller.saveConfig),
          ],
        );
      }),
    );
  }
}

class _MasterSwitchCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MasterSwitchCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = value ? Colors.green : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
            alignment: Alignment.center,
            child: Icon(Icons.notifications_active_outlined, color: color),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notificações', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 2),
                Text('Ative para receber os alertas abaixo.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _AlertTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.04))],
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(value: value, onChanged: enabled ? onChanged : null),
          ],
        ),
      ),
    );
  }
}
