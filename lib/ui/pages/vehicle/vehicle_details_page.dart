import 'package:app_tracking/app/services/km_report_pdf.dart';
import 'package:app_tracking/ui/controllers/vehicles/vehicles_detail_controller.dart';
import 'package:app_tracking/ui/pages/map/map_page.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/data_filter.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/km_day_item.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/km_per_day_card.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

class VehicleDetailsPage extends GetView<VehicleDetailsController> {
  final int deviceId;

  const VehicleDetailsPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalhes do Veículo")),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.picture_as_pdf),
        onPressed: () {
          KmReportPdfService.generate(deviceName: 'Moto', data: controller.dailyKmList);
        },
      ),
      body: Obx(() {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DateFilterCard(controller: controller),

            if (controller.isLoading.value) const Center(child: CircularProgressIndicator()),

            if (!controller.isLoading.value) ...controller.dailyKmList.map((item) => KmDayItem(item: item)),
            const SizedBox(height: 16),
            KmPerDayCard(km: controller.totalKm.value),
            MapWidget(deviceId: deviceId),
          ],
        );
      }),
    );
  }
}
