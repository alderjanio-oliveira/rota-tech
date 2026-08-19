import 'package:app_tracking/app/services/km_report_pdf.dart';
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/distance_reminder_model.dart';
import 'package:app_tracking/data/tracker_sms_command.dart';
import 'package:app_tracking/ui/controllers/vehicles/vehicles_detail_controller.dart';
import 'package:app_tracking/ui/molecules/modal/modal_generic_molecule.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/data_filter.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/km_day_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleDetailsPage extends GetView<VehicleDetailsController> {
  final DeviceModel device;

  const VehicleDetailsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(device.name)),

      /// ✅ FAB CORRETO
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Relatório"),
        onPressed: () {
          KmReportPdfService.generate(deviceName: device.name, data: controller.dailyKmList);
        },
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// 🚗 HEADER
          _VehicleHeader(device: controller.device),

          Obx(
            () => controller.reminderReached
                ? const Padding(padding: EdgeInsets.only(top: 16), child: _TripTargetReachedBanner())
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          /// 👤 VÍNCULO
          _LinkedClientCard(controller: controller),

          const SizedBox(height: 16),

          /// 📊 KPIs (SEM QUEBRAR)
          _KpiSection(controller: controller),

          const SizedBox(height: 16),

          /// 📡 COMANDOS SMS — configuração do rastreador (APN, servidor,
          /// etc.), enviados direto pro chip.
          _SmsCommandsSection(controller: controller),

          const SizedBox(height: 24),

          /// 🧾 HISTÓRICO DE METAS ZERADAS (Trip A) — vem da mesma tabela do
          /// backend, só que trazendo o que já foi confirmado/cancelado.
          Obx(() {
            if (controller.reminderHistory.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histórico de quilometragem zerada',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...controller.reminderHistory.map(
                  (reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ReminderHistoryItem(reminder: reminder),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),

          Text('Últimas quilometragens', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Consultado direto no servidor — não existe um histórico salvo localmente. Use o filtro para escolher o período.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 12),

          /// 🎯 FILTRO
          DateFilterCard(controller: controller),

          const SizedBox(height: 12),

          /// 📈 LISTA — carregamento isolado, não trava o resto da tela.
          Obx(() {
            if (controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.dailyKmList.isEmpty) {
              return const Column(
                children: [
                  Icon(Icons.insights, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("Nenhum dado no período"),
                ],
              );
            }
            return Column(
              children: controller.dailyKmList
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KmDayItem(item: item),
                    ),
                  )
                  .toList(),
            );
          }),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  final DeviceModel device;

  const _VehicleHeader({required this.device});

  @override
  Widget build(BuildContext context) {
    final isOn = device.attributes.ignition == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(context).cardColor),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isOn ? Colors.green : Colors.grey,
            child: const Icon(Icons.directions_car, color: Colors.white),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  isOn ? "Ligado agora" : "Desligado",
                  style: TextStyle(color: isOn ? Colors.green : Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTargetReachedBanner extends StatelessWidget {
  const _TripTargetReachedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Este veículo já atingiu a meta de quilometragem da Trip A. Registre uma nova meta para limpar este aviso.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkedClientCard extends StatelessWidget {
  final VehicleDetailsController controller;

  const _LinkedClientCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isAdmin = Get.find<UserSessionService>().isAdmin.value;

    return Obx(() {
      final client = controller.linkedClient.value;
      final isLoading = controller.isLoadingClient.value;
      final canNavigate = isAdmin && client != null;
      final color = Theme.of(context).colorScheme.primary;

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.04))],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: canNavigate ? () => Get.toNamed(Routes.CLIENTS_DETAILS, arguments: client) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 22, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vinculado a', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text(
                        isLoading ? 'Carregando...' : (client?.name ?? 'Nenhum cliente vinculado'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: canNavigate ? color : null,
                          decoration: canNavigate ? TextDecoration.underline : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canNavigate) const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _KpiSection extends StatelessWidget {
  final VehicleDetailsController controller;

  const _KpiSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(context).cardColor),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoadingReminder.value || controller.isSavingReminder.value) {
                return _KpiItem(label: "Trip A", value: null, icon: Icons.route, onTap: () => _showReminderForm(context));
              }
              final traveled = controller.reminderTraveledKm;
              final target = controller.reminderTargetKm;
              final tripValue = target == null ? 'Sem meta' : '${(traveled ?? 0).toStringAsFixed(1)} / ${target.toStringAsFixed(0)} km';
              return _KpiItem(label: "Trip A", value: tripValue, icon: Icons.route, onTap: () => _showReminderForm(context));
            }),
          ),
          Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.3)),
          Expanded(
            child: Obx(() => _KpiItem(label: "Total", value: "${controller.totalKm.value.toStringAsFixed(2)} km", icon: Icons.speed)),
          ),
        ],
      ),
    );
  }

  void _showReminderForm(BuildContext context) {
    final current = controller.activeReminder.value;
    final nameController = TextEditingController(text: current?.name ?? 'Troca de óleo');
    final targetController = TextEditingController(text: controller.reminderTargetKm?.toStringAsFixed(0) ?? '1000');

    GenericModalMolecule.show(
      context: context,
      title: current == null ? 'Nova meta de km' : 'Zerar e nova meta',
      description: current == null
          ? 'Dê um nome ao lembrete e informe a meta em km'
          : 'O lembrete atual será encerrado e um novo será criado a partir de agora',
      primaryMethod: () async {
        final name = nameController.text.trim();
        final target = double.tryParse(targetController.text.replaceAll(',', '.'));

        if (name.isEmpty) {
          Get.snackbar('Nome obrigatório', 'Dê um nome ao lembrete.');
          return;
        }
        if (target == null || target <= 0) {
          Get.snackbar('Meta inválida', 'Informe uma meta maior que zero.');
          return;
        }

        final success = await controller.saveReminder(name: name, targetKm: target);
        if (!success) {
          Get.snackbar('Erro', controller.reminderError.value ?? 'Não foi possível salvar o lembrete.');
        } else {
          Get.snackbar('Meta salva', 'A meta de quilometragem foi registrada.');
        }
      },
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: targetController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Meta (km)', border: OutlineInputBorder()),
          ),
        ],
      ),
      secondyMethod: () {},
    );
  }
}

/// Item do histórico de metas de km já concluídas/canceladas.
class _ReminderHistoryItem extends StatelessWidget {
  final DistanceReminder reminder;

  const _ReminderHistoryItem({required this.reminder});

  @override
  Widget build(BuildContext context) {
    final isDone = reminder.status == DistanceReminder.statusDone;
    final date = reminder.confirmedAt ?? reminder.cancelledAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Theme.of(context).cardColor),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: isDone ? Colors.green : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reminder.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  isDone
                      ? '${(reminder.traveledDistance / 1000).toStringAsFixed(2)} / ${(reminder.thresholdDistance / 1000).toStringAsFixed(0)} km'
                      : 'Cancelado',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (date != null) Text(_formatDate(date), style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

/// Comandos de configuração do rastreador, enviados por SMS pro chip.
/// Só pro admin (operador da frota) — um cliente vendo os detalhes do
/// próprio veículo não pode reconfigurar o rastreador dele.
/// Fechado por padrão pra não poluir a tela — só quem precisa reconfigurar
/// (recém-cadastrado ou depois de um reset) abre.
class _SmsCommandsSection extends StatelessWidget {
  final VehicleDetailsController controller;

  const _SmsCommandsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!Get.find<UserSessionService>().isAdmin.value) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Theme.of(context).cardColor),
        child: ExpansionTile(
          title: const Text('Comandos de configuração (SMS)', style: TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(
            controller.liveDevice.phone?.isNotEmpty == true
                ? 'Enviados pro chip ${controller.liveDevice.phone}'
                : 'Dispositivo sem número de chip cadastrado',
            style: const TextStyle(fontSize: 12),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: controller.commands.map((command) => _CommandCard(command: command, controller: controller)).toList(),
        ),
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  final SmsCommandTemplate command;
  final VehicleDetailsController controller;

  const _CommandCard({required this.command, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(command.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (command.required)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text(
                    'Obrigatório',
                    style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(command.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (command.params.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: command.params.map((param) {
                return SizedBox(
                  width: 150,
                  child: TextField(
                    controller: controller.paramControllers['${command.label}.${param.key}'],
                    decoration: InputDecoration(labelText: param.label, isDense: true),
                    onChanged: (_) => controller.refreshPreview(command),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 10),
          Obx(
            () => Text(
              controller.previewByCommand[command.label]?.value ?? '',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => controller.copyCommand(command),
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text('Copiar'),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                onPressed: () => controller.sendBySms(command),
                icon: const Icon(Icons.sms_outlined, size: 16),
                label: const Text('Enviar por SMS'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback? onTap;

  const _KpiItem({required this.label, required this.value, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          value == null
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(value!, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
