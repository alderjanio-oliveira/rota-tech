// lib/ui/pages/home/home_page.dart
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/ui/drawer/app_drawer.dart';
import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:app_tracking/ui/controllers/home_controller.dart';
import 'package:app_tracking/ui/molecules/device_card/device_card.dart';
import 'package:app_tracking/ui/molecules/modal/modal_generic_molecule.dart';
import 'package:app_tracking/ui/molecules/notification_bell.dart';
import 'package:app_tracking/ui/pages/home/widgets/egine_action_modal.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Testar notificações',
            onPressed: controller.triggerNotificationWorkerTest,
            icon: const Icon(Icons.bug_report_outlined),
          ),
          IconButton(onPressed: () => Get.toNamed(Routes.MAP), icon: Icon(Icons.map)),
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.loadDevices),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      drawer: const AppDrawer(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Carregando dispositivos...'),
              ],
            ),
          );
        }

        // if (controller.errorMessage.value.isNotEmpty) {
        //   return Center(
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Text(controller.errorMessage.value),
        //         const SizedBox(height: 16),
        //         PrimaryButton(text: 'Tentar Novamente', onPressed: controller.loadDevices),
        //       ],
        //     ),
        //   );
        // }

        if (controller.vehicles.list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.directions_car_outlined, size: 48),
                SizedBox(height: 12),
                Text('Nenhum dispositivo encontrado'),
              ],
            ),
          );
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
                  // charge: device.attributes.charge,
                  address: device.attributes.address,
                  // id: device.id,
                  totalDistance: device.attributes.totalDistance ?? 0.0,
                  ignitionStatus: device.attributes.ignition,
                  deviceName: device.name,
                  status: device.status,
                  // lastUpdate: device.lastPositionId,
                  loading: device.loading.value,
                  onTap: () => GenericModalMolecule.show(
                    context: context,
                    title: 'Deseja ver os detalhes do veículo?',
                    primaryMethod: () => Get.toNamed(Routes.VEHICLE_DETAILS, arguments: device),
                    secondyMethod: () => Get.back(),
                  ),
                  // resetTrip: () {
                  //   GetStorage box = GetStorage();
                  //   // box.write(
                  //   //   'OffSetTripA${device['id']}',
                  //   //   device['attributes']?['totalDistance'] ?? 0.0,
                  //   // );
                  // },
                  actions: [
                    Obx(() {
                      final lockState = device.attributes.lockState;

                      final isLoading = device.loading.value;
                      final isBlocked = lockState.value == true;

                      if (isLoading) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      return GestureDetector(
                        onTap: () {
                          if (lockState.value == null) {
                            /// 🔥 fallback original (mantido)
                            EngineActionModal.show(
                              context: context,
                              onEngineOn: () => controller.sendCommand(index, 'engineResume'),
                              onEngineOff: () => controller.sendCommand(index, 'engineStop'),
                            );
                            return;
                          }

                          /// 🔒 NOVO: CONFIRMAÇÃO
                          _confirmToggle(
                            context,
                            isBlocked,
                            onConfirm: () {
                              controller.sendCommand(
                                index,
                                isBlocked ? 'engineResume' : 'engineStop',
                              );
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isBlocked ? Colors.red : Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isBlocked ? Icons.lock : Icons.lock_open,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      );
                    }),
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

void _confirmToggle(BuildContext context, bool isBlocked, {required VoidCallback onConfirm}) {
  Get.dialog(
    AlertDialog(
      title: Text(isBlocked ? "Desbloquear veículo" : "Bloquear veículo"),
      content: Text(
        isBlocked ? "Deseja liberar o veículo?" : "Deseja BLOQUEAR o veículo? Isso pode desligá-lo remotamente.",
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isBlocked ? Colors.green : Colors.red,
          ),
          onPressed: () {
            Get.back();
            onConfirm();
          },
          child: Text(isBlocked ? "Desbloquear" : "Bloquear"),
        ),
      ],
    ),
  );
}
