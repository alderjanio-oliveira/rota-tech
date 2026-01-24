// lib/ui/pages/home/home_page.dart
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/ui/drawer/app_drawer.dart';
import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/ui/atoms/button/primary.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:app_tracking/ui/controllers/home_controller.dart';
import 'package:app_tracking/ui/molecules/device_card/device_card.dart';
import 'package:app_tracking/ui/pages/home/widgets/action_button.dart';
import 'package:app_tracking/ui/pages/home/widgets/egine_action_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.loadDevices),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.errorMessage.value),
                const SizedBox(height: 16),
                PrimaryButton(text: 'Tentar Novamente', onPressed: controller.loadDevices),
              ],
            ),
          );
        }

        if (controller.devices.isEmpty) {
          return const Center(child: Text('Nenhum dispositivo encontrado'));
        }

        return Obx(
          () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.devices.length,
            itemBuilder: (context, index) {
              final device = controller.devices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeviceCard(
                  charge: device.attributes.charge,
                  address: device.attributes.address,
                  id: device.id,
                  totalDistance: device.attributes.totalDistance ?? 0.0,
                  ignitionStatus: device.attributes.ignition,
                  deviceName: device.name,
                  status: device.status,
                  lastUpdate: device.lastPositionId,
                  onTap: () => _showDeviceDetails(device),
                  resetTrip: () {
                    GetStorage box = GetStorage();
                    // box.write(
                    //   'OffSetTripA${device['id']}',
                    //   device['attributes']?['totalDistance'] ?? 0.0,
                    // );
                  },
                  actions: [
                    ActionButton(
                      tooltip: 'Engine',
                      icon: device.attributes.lockState == true ? Icons.lock_sharp : Icons.lock_open_sharp,
                      locked: device.attributes.lockState == null ? null : !device.attributes.lockState!,
                      onPressed: () {
                        final lockState = device.attributes.lockState;

                        if (lockState == null) {
                          EngineActionModal.show(
                            context: context,
                            onEngineOn: () => controller.sendCommand(device.id, 'engineResume'),
                            onEngineOff: () => controller.sendCommand(device.id, 'engineStop'),
                          );
                          return;
                        }

                        controller.sendCommand(device.id, lockState ? 'engineResume' : 'engineStop');
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _showDeviceDetails(DeviceModel device) {
    Get.dialog(
      AlertDialog(
        title: Text(device.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${device.id}'),
            Text('Status: ${device.status}'),
            if (device.lastPositionId != null) Text('Última atualização: ${device.lastPositionId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.toNamed(Routes.VEHICLE_DETAILS, arguments: device.id);
            },
            child: const Text('Ver Detalhes'),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('Fechar')),
        ],
      ),
    );
  }

  void _logout() {
    Get.find<AuthController>().logout();
    Get.offAllNamed('/login');
  }
}
