import 'package:app_tracking/app/services/km_report_pdf.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/ui/controllers/vehicles/vehicles_detail_controller.dart';
import 'package:app_tracking/ui/molecules/modal/modal_generic_molecule.dart';
import 'package:app_tracking/ui/pages/map/map_page.dart';
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
      appBar: AppBar(
        title: Text(device.name),
      ),

      /// ✅ FAB CORRETO
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Relatório"),
        onPressed: () {
          KmReportPdfService.generate(
            deviceName: device.name,
            data: controller.dailyKmList,
          );
        },
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// 🗺️ MAPA (DESTAQUE)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: MapWidget(
                deviceId: controller.device.id,
                height: 260,
              ),
            ),

            const SizedBox(height: 16),

            /// 🚗 HEADER
            _VehicleHeader(device: controller.device),

            const SizedBox(height: 16),

            /// 📊 KPIs (SEM QUEBRAR)
            _KpiSection(controller: controller),

            const SizedBox(height: 16),

            /// 🎯 FILTRO
            DateFilterCard(controller: controller),

            const SizedBox(height: 16),

            /// 📈 LISTA
            if (controller.dailyKmList.isEmpty)
              Column(
                children: const [
                  Icon(Icons.insights, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text("Nenhum dado no período"),
                ],
              )
            else
              ...controller.dailyKmList.map(
                (item) => KmDayItem(item: item),
              ),

            const SizedBox(height: 100),
          ],
        );
      }),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
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
                Text(
                  device.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  isOn ? "Ligado agora" : "Desligado",
                  style: TextStyle(
                    color: isOn ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  final VehicleDetailsController controller;

  const _KpiSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: _KpiItem(
              label: "Trip A",
              value: controller.tripFormatted,
              icon: Icons.route,
              onTap: () => _showReset(context),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withOpacity(0.3),
          ),
          Expanded(
            child: _KpiItem(
              label: "Total",
              value: "${controller.totalKm.value} km",
              icon: Icons.speed,
            ),
          ),
        ],
      ),
    );
  }

  void _showReset(BuildContext context) {
    GenericModalMolecule.show(
      context: context,
      title: 'Zerar Trip',
      description: 'Informe a meta em KM',
      primaryMethod: () {
        Get.back();
        controller.resetTip(
          'trip A',
          controller.target.text.isEmpty ? 0.0 : double.tryParse(controller.target.text) ?? 0.0,
        );
      },
      body: TextFormField(
        controller: controller.target,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Meta (km)'),
      ),
      secondyMethod: () => Get.back(),
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
