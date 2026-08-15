import 'package:app_tracking/app/services/km_report_pdf.dart';
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/device_model.dart';
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
            () =>
                controller.reminderReached
                    ? const Padding(padding: EdgeInsets.only(top: 16), child: _TripTargetReachedBanner())
                    : const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          /// 👤 VÍNCULO
          _LinkedClientCard(controller: controller),

          const SizedBox(height: 16),

          /// 📊 KPIs (SEM QUEBRAR)
          _KpiSection(controller: controller),

          const SizedBox(height: 24),

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
              return const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()));
            }
            if (controller.dailyKmList.isEmpty) {
              return const Column(
                children: [Icon(Icons.insights, size: 40, color: Colors.grey), SizedBox(height: 8), Text("Nenhum dado no período")],
              );
            }
            return Column(
              children:
                  controller.dailyKmList
                      .map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: KmDayItem(item: item)))
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
      description:
          current == null
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
