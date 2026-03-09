import 'package:app_tracking/app/services/km_report_pdf.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/ui/controllers/vehicles/vehicles_detail_controller.dart';
import 'package:app_tracking/ui/molecules/modal/modal_generic_molecule.dart';
import 'package:app_tracking/ui/pages/map/map_page.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/data_filter.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/km_day_item.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/km_per_day_card.dart';
import 'package:app_tracking/ui/pages/vehicle/widgets/trip_car.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleDetailsPage extends GetView<VehicleDetailsController> {
  final DeviceModel device;

  const VehicleDetailsPage({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    controller.tripCalculate();
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
            Card(
              child: ListTile(
                title: Text('Veículo: ${controller.device.name}'),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: TripCard(
                        target: controller.target,
                        label: 'Trip A',
                        valueKm: controller.tripFormatted,
                        onReset: () => GenericModalMolecule.show(
                          context: context,
                          title: 'Deseja zerar a quilometragem?',
                          description: 'Informe com quantos kms deseja ser notificado',
                          primaryMethod: () {
                            Get.back();
                            controller.resetTip(
                              'trip A',
                              controller.target.text.isEmpty ? 0.0 : double.tryParse(controller.target.text) ?? 0.0,
                            );
                          },
                          body: Form(
                            child: TextFormField(
                              controller: controller.target,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Meta (km)'),
                            ),
                          ),
                          secondyMethod: () => Get.back(),
                        ),
                      ),
                    ),
                    // Text('trip A: ${controller.tripFormatted} km'),
                  ],
                ),
              ),
            ),
            DateFilterCard(controller: controller),

            if (controller.isLoading.value) const Center(child: CircularProgressIndicator()),

            if (!controller.isLoading.value) ...controller.dailyKmList.map((item) => KmDayItem(item: item)),
            const SizedBox(height: 16),
            KmPerDayCard(km: controller.totalKm.value),
            MapWidget(deviceId: controller.device.id),
          ],
        );
      }),
    );
  }
}
