// lib/ui/pages/home/home_page.dart
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/ui/drawer/app_drawer.dart';
import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:app_tracking/ui/controllers/home_controller.dart';
import 'package:app_tracking/ui/molecules/device_card/device_card.dart';
import 'package:app_tracking/ui/molecules/device_card/device_card_skeleton.dart';
import 'package:app_tracking/ui/molecules/modal/modal_generic_molecule.dart';
import 'package:app_tracking/ui/molecules/notification_bell.dart';
import 'package:app_tracking/ui/pages/home/widgets/egine_action_modal.dart';
import 'package:app_tracking/ui/pages/map/map_page.dart';
import 'package:app_tracking/ui/theme/app_colors.dart';
import 'package:app_tracking/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Nº mínimo de caracteres pra começar a sugerir devices na busca.
const int kSearchSuggestionsMinChars = 2;

/// Nº máximo de sugestões exibidas.
const int kSearchSuggestionsLimit = 4;

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Dispositivos', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          const NotificationBell(),
          IconButton(icon: const Icon(Icons.refresh), onPressed: controller.loadDevices),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _SoftCard(
                    borderRadius: 24,
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: (v) => controller.search.value = v,
                      decoration: InputDecoration(
                        hintText: 'Buscar dispositivo...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Obx(
                          () =>
                              controller.search.value.isEmpty
                                  ? const SizedBox.shrink()
                                  : IconButton(icon: const Icon(Icons.close), onPressed: controller.clearSearch),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(
                  () => _SoftCard(
                    borderRadius: 100,
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ViewModeButton(
                          icon: Icons.view_list_rounded,
                          tooltip: 'Ver lista',
                          selected: !controller.isMapView.value,
                          onTap: () {
                            if (controller.isMapView.value) controller.toggleMapView();
                          },
                        ),
                        _ViewModeButton(
                          icon: Icons.map_rounded,
                          tooltip: 'Ver mapa',
                          selected: controller.isMapView.value,
                          onTap: () {
                            if (!controller.isMapView.value) controller.toggleMapView();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final query = controller.search.value.trim();
            if (query.length < kSearchSuggestionsMinChars) return const SizedBox.shrink();

            final normalizedQuery = Utils.normalizeSearch(query);
            final suggestions =
                controller.vehicles.list
                    .where((d) => Utils.normalizeSearch(d.name).contains(normalizedQuery))
                    .take(kSearchSuggestionsLimit)
                    .toList();

            if (suggestions.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _SoftCard(
                borderRadius: 16,
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      suggestions
                          .map(
                            (d) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.directions_car_outlined, size: 20),
                              title: Text(d.name),
                              onTap: () {
                                controller.selectSearchSuggestion(d.name);
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          )
                          .toList(),
                ),
              ),
            );
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [CircularProgressIndicator(), SizedBox(height: 16), Text('Carregando dispositivos...')],
                  ),
                );
              }

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

              return IndexedStack(
                index: controller.isMapView.value ? 1 : 0,
                children: [
                  Obx(() {
                    final query = Utils.normalizeSearch(controller.search.value.trim());
                    final devices =
                        query.isEmpty
                            ? controller.vehicles.list
                            : controller.vehicles.list.where((d) => Utils.normalizeSearch(d.name).contains(query)).toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];

                        if (!device.positionLoaded) {
                          return const DeviceCardSkeleton();
                        }

                        // Índice real em vehicles.list (pode diferir do índice
                        // na lista filtrada pela busca).
                        final deviceIndex = controller.vehicles.list.indexOf(device);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DeviceCard(
                            address: device.attributes.address,
                            totalDistance: device.attributes.totalDistance ?? 0.0,
                            ignitionStatus: device.attributes.ignition,
                            deviceName: device.name,
                            status: device.status,
                            loading: device.loading.value,
                            charge: device.attributes.charge,
                            onTap:
                                () => GenericModalMolecule.show(
                                  context: context,
                                  title: 'Deseja ver os detalhes do veículo?',
                                  primaryMethod: () => Get.toNamed(Routes.VEHICLE_DETAILS, arguments: device),
                                  secondyMethod: () => Get.back(),
                                ),
                            actions: [
                              Obx(() {
                                final lockState = device.attributes.lockState;

                                final isLoading = device.loading.value;
                                final isBlocked = lockState.value == true;
                                final lockColor =
                                    lockState.value == null ? AppColors.gray : (isBlocked ? AppColors.error : AppColors.success);

                                if (isLoading) {
                                  return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                                }

                                return GestureDetector(
                                  onTap: () {
                                    if (lockState.value == null) {
                                      /// 🔥 fallback original (mantido)
                                      EngineActionModal.show(
                                        context: context,
                                        onEngineOn: () => controller.sendCommand(deviceIndex, 'engineResume'),
                                        onEngineOff: () => controller.sendCommand(deviceIndex, 'engineStop'),
                                      );
                                      return;
                                    }

                                    /// 🔒 NOVO: CONFIRMAÇÃO
                                    _confirmToggle(
                                      context,
                                      isBlocked,
                                      onConfirm: () {
                                        controller.sendCommand(deviceIndex, isBlocked ? 'engineResume' : 'engineStop');
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: lockColor, shape: BoxShape.circle),
                                    child: Icon(isBlocked ? Icons.lock : Icons.lock_open, color: Colors.white, size: 16),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                  MapWidget(searchQuery: controller.search),
                ],
              );
            }),
          ),
        ],
      ),
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
      content: Text(isBlocked ? "Deseja liberar o veículo?" : "Deseja BLOQUEAR o veículo? Isso pode desligá-lo remotamente."),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text("Cancelar")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: isBlocked ? AppColors.success : AppColors.error),
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

/// Botão de um controle segmentado lista/mapa — deixa explícito qual dos
/// dois modos está ativo (em vez de um ícone só trocando de forma ambígua).
class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ViewModeButton({required this.icon, required this.tooltip, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(color: selected ? AppColors.primary.withOpacity(0.15) : Colors.transparent, shape: BoxShape.circle),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 20, color: selected ? AppColors.primary : AppColors.gray),
      ),
    );
  }
}

/// Card arredondado com sombra suave — usado na busca e no botão de troca de
/// visualização pra não parecerem colados na appbar.
class _SoftCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const _SoftCard({required this.child, this.borderRadius = 16, this.padding = const EdgeInsets.symmetric(horizontal: 4)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05))],
      ),
      child: child,
    );
  }
}
