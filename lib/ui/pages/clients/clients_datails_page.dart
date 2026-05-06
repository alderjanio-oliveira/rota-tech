import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/ui/controllers/clients_details_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum _ClientAction { edit, sendClientInfo, sendBilling, sendContractOk }

class ClientsDatailsPage extends GetView<ClientsDetailsController> {
  const ClientsDatailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Cliente')),
      body: Obx(() {
        final linkedDevices = controller.linkedDevices;
        final availableDevices = controller.availableDevices;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(
              name: controller.clientName.value,
              daysToExpire: controller.daysToExpire,
              expiresAt: controller.formatDate(controller.expiresAt.value),
              onEdit: () => _openEditSheet(context),
              onSendClientInfo: controller.sendClientInfoMessage,
              onSendBilling: controller.sendBillingMessage,
              onSendContractOk: controller.sendContractOkMessage,
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Veículos vinculados',
              trailing: '${linkedDevices.length}',
              child: controller.isLoadingLinks.value
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : linkedDevices.isEmpty
                      ? const _EmptyState(text: 'Nenhum veículo vinculado a este cliente.')
                      : Column(
                          children: linkedDevices.map((device) {
                            return _DeviceTile(
                              device: device,
                              icon: Icons.link_off,
                              actionLabel: 'Remover vínculo',
                              onTap: () => controller.confirmUnlink(device),
                            );
                          }).toList(),
                        ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Adicionar veículo',
              child: Column(
                children: [
                  TextField(
                    controller: controller.vehicleSearchController,
                    onChanged: (value) => controller.vehicleSearch.value = value,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nome ou ID',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (controller.vehicleSearch.value.trim().isEmpty)
                    const _EmptyState(text: 'Digite para localizar um veículo disponível.')
                  else if (availableDevices.isEmpty)
                    const _EmptyState(text: 'Nenhum veículo encontrado para essa busca.')
                  else
                    Column(
                      children: availableDevices.map((device) {
                        return _DeviceTile(
                          device: device,
                          icon: Icons.add_link,
                          actionLabel: 'Vincular veículo',
                          onTap: () => controller.confirmLink(device),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 32,
          ),
          child: Obx(() {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Editar cliente',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: Get.back,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.nameController,
                    decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.alternate_email)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nova senha',
                      hintText: 'Deixe em branco para manter a atual',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => controller.pickExpirationDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de expiração',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      child: Text(controller.formatDate(controller.expiresAt.value)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isSaving.value ? null : controller.saveClient,
                      icon: controller.isSaving.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(controller.isSaving.value ? 'Salvando...' : 'Salvar alterações'),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final int daysToExpire;
  final String expiresAt;
  final VoidCallback onEdit;
  final VoidCallback onSendClientInfo;
  final VoidCallback onSendBilling;
  final VoidCallback onSendContractOk;

  const _Header({
    required this.name,
    required this.daysToExpire,
    required this.expiresAt,
    required this.onEdit,
    required this.onSendClientInfo,
    required this.onSendBilling,
    required this.onSendContractOk,
  });

  @override
  Widget build(BuildContext context) {
    final color = daysToExpire < 0 ? Colors.red : (daysToExpire <= 5 ? Colors.orange : Colors.green);
    final status = daysToExpire < 0 ? '${daysToExpire.abs()} dias em atraso' : (daysToExpire == 0 ? 'Vence hoje' : '$daysToExpire dias restantes');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.18),
            child: Icon(Icons.person, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Vencimento: $expiresAt', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<_ClientAction>(
                tooltip: 'Ações',
                icon: const Icon(Icons.more_vert),
                onSelected: (action) {
                  switch (action) {
                    case _ClientAction.edit:
                      onEdit();
                      break;
                    case _ClientAction.sendClientInfo:
                      onSendClientInfo();
                      break;
                    case _ClientAction.sendBilling:
                      onSendBilling();
                      break;
                    case _ClientAction.sendContractOk:
                      onSendContractOk();
                      break;
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _ClientAction.edit, child: Text('Editar')),
                  PopupMenuItem(value: _ClientAction.sendClientInfo, child: Text('Enviar contrato')),
                  PopupMenuItem(value: _ClientAction.sendBilling, child: Text('Enviar cobrança')),
                  PopupMenuItem(value: _ClientAction.sendContractOk, child: Text('Contrato em dias')),
                ],
              ),
              Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (trailing != null)
                Chip(
                  label: Text(trailing!),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final DeviceModel device;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.device,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Icon(Icons.directions_car_outlined, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('ID ${device.id} - Status: ${device.status}'),
      trailing: IconButton(
        tooltip: actionLabel,
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;

  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
