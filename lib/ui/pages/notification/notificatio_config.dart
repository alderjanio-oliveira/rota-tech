import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/ui/atoms/button/primary.dart';
import 'package:app_tracking/ui/atoms/switch/custom_switch.dart';
import 'package:app_tracking/ui/controllers/notification/notificationConfig_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationConfigPage extends GetView<NotificationConfigController> {
  const NotificationConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text('NotificatioConfig')),

      body: Column(
        children: [
          LabelSwitchTile(
            label: 'Ativar Notificações',
            value: controller.isEnabled,
            onChanged: (value) => controller.allOptions(value),
          ),
          Divider(),
          LabelSwitchTile(
            label: 'Status de ignição',
            value: controller.ignitionAlert,
          ),
          LabelSwitchTile(
            label: 'Desligamento de bateria',
            value: controller.chargeAlert,
          ),
          LabelSwitchTile(
            label: 'Status de kilometragem',
            value: controller.tripAlert,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: PrimaryButton(text: 'Save', onPressed: controller.saveConfig),
          ),
        ],
      ),
    );
  }
}
