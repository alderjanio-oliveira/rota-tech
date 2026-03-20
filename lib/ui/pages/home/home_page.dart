// lib/ui/pages/home/home_page.dart
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/ui/drawer/app_drawer.dart';
import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/ui/atoms/button/primary.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:app_tracking/ui/controllers/home_controller.dart';
import 'package:app_tracking/ui/molecules/device_card/device_card.dart';
import 'package:app_tracking/ui/molecules/modal/modal_generic_molecule.dart';
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
          IconButton(onPressed: () => Get.toNamed(Routes.MAP), icon: Icon(Icons.map)),
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

        if (controller.vehicles.list.isEmpty) {
          return const Center(child: Text('Nenhum dispositivo encontrado'));
        }

        return Obx(
          () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.vehicles.list.length,
            itemBuilder: (context, index) {
              final device = controller.vehicles.list[index];
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
                  loading: device.loading,
                  onTap: () => GenericModalMolecule.show(
                    context: context,
                    title: 'Deseja ver os detalhes do veículo?',
                    primaryMethod: () => Get.toNamed(Routes.VEHICLE_DETAILS, arguments: device),
                    secondyMethod: () => Get.back(),
                  ),
                  resetTrip: () {
                    GetStorage box = GetStorage();
                    // box.write(
                    //   'OffSetTripA${device['id']}',
                    //   device['attributes']?['totalDistance'] ?? 0.0,
                    // );
                  },
                  actions: [
                    Obx(
                      () => device.loading.value
                          ? CircularProgressIndicator()
                          : ActionButton(
                              tooltip: 'Engine',
                              icon: device.attributes.lockState == true ? Icons.lock_sharp : Icons.lock_open_sharp,
                              locked: device.attributes.lockState.value == null ? null : !device.attributes.lockState.value!,
                              onPressed: () {
                                final lockState = device.attributes.lockState;

                                if (lockState.value == null) {
                                  EngineActionModal.show(
                                    context: context,
                                    onEngineOn: () => controller.sendCommand(index, 'engineResume'),
                                    onEngineOff: () => controller.sendCommand(index, 'engineStop'),
                                  );
                                  return;
                                }
                                controller.sendCommand(index, lockState.value! ? 'engineResume' : 'engineStop');
                              },
                            ),
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

  void _logout() {
    Get.find<AuthController>().logout();
    Get.offAllNamed('/login');
  }
}
