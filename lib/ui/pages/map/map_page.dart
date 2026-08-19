import 'dart:async';

import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/ui/atoms/status_badge.dart';
import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:app_tracking/ui/model/positiion_model.dart';
import 'package:app_tracking/ui/molecules/modal/modal_generic_molecule.dart';
import 'package:app_tracking/ui/pages/home/widgets/egine_action_modal.dart';
import 'package:app_tracking/ui/theme/app_colors.dart';
import 'package:app_tracking/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MapWidget extends StatefulWidget {
  final int? deviceId;

  /// Restringe o mapa a esses devices (ex.: todas as motos de um cliente).
  /// Tem prioridade sobre [deviceId].
  final List<int>? deviceIds;

  /// Rótulo do balão de filtro (ex.: nome do cliente) — só aparece junto
  /// com [deviceIds]. Some com o "x" pra voltar à visualização padrão.
  final String? filterLabel;

  /// Altura fixa (ex.: quando embutido num card/lista). Se nulo, o mapa
  /// preenche o espaço disponível do pai (ex.: dentro de um IndexedStack).
  final double? height;

  /// Texto de busca (ex.: da Home) — quando casa com um único device,
  /// o mapa centraliza e seleciona ele.
  final RxString? searchQuery;

  const MapWidget({super.key, this.deviceId, this.deviceIds, this.filterLabel, this.height, this.searchQuery});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final controller = Get.find<MapCustomController>();
  final MapController mapController = MapController();

  bool _initialCameraSet = false;
  bool _followVehicle = true;
  int? _selectedDeviceId;

  StreamSubscription<String>? _searchSub;

  @override
  void initState() {
    super.initState();

    controller.init(deviceId: widget.deviceId, deviceIds: widget.deviceIds, filterLabel: widget.filterLabel);

    controller.onPositionUpdated = (position) {
      if (_followVehicle && controller.devices.length == 1) {
        mapController.move(position, mapController.camera.zoom);
      }
    };

    if (widget.searchQuery != null) {
      _searchSub = widget.searchQuery!.listen(_focusFromSearch);
    }
  }

  @override
  void dispose() {
    _searchSub?.cancel();
    super.dispose();
  }

  void _focusFromSearch(String query) {
    final q = Utils.normalizeSearch(query.trim());
    if (q.isEmpty) return;

    final matches = controller.devices.where((d) => Utils.normalizeSearch(d.name).contains(q)).toList();
    if (matches.length != 1) return;

    final device = matches.first;
    controller.clearRoute();
    setState(() => _selectedDeviceId = device.id);
    mapController.move(LatLng(device.latitude, device.longitude), 17);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stack = Stack(
      children: [
        /// 🗺️ MAPA
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            onTap: (_, __) {
              controller.clearRoute();
              setState(() {
                _selectedDeviceId = null;
              });
            },
          ),
          children: [
            /// TILE — Mapbox streets-v12 / dark-v11. Atenção: ordem padrão
            /// {z}/{x}/{y} (diferente da Esri, que usava {z}/{y}/{x}).
            TileLayer(
              urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/${isDark ? "dark-v11" : "streets-v12"}/tiles/{z}/{x}/{y}{r}'
                  '?access_token=${dotenv.env['MAP_BOX_TOKEN']}',
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: 'com.mobgotech.rotatec',
            ),

            /// TRILHAS — cada trecho (entre hiatos de sinal) é uma Polyline
            /// separada, então um hiato (tela bloqueada, sem sinal) aparece
            /// como uma quebra na trilha, nunca como uma linha reta ligando
            /// o ponto de antes ao de depois.
            Obx(() {
              final polylines = <Polyline>[
                for (final segments in controller.trails.values)
                  for (final segment in segments)
                    if (segment.length > 1)
                      Polyline(
                        points: segment,
                        strokeWidth: 4,
                        color: AppColors.primary.withOpacity(0.85),
                        borderStrokeWidth: 1.5,
                        borderColor: (isDark ? Colors.black : Colors.white).withOpacity(0.6),
                      ),
              ];

              if (polylines.isEmpty) return const SizedBox();

              return PolylineLayer(polylines: polylines);
            }),

            /// ROTA até o veículo selecionado — tracejada, cor diferente da
            /// trilha (que é o caminho já percorrido; essa é a pra chegar lá).
            Obx(() {
              final route = controller.routeToDevice.value;
              if (route == null || route.length < 2) return const SizedBox();

              return PolylineLayer(
                polylines: [
                  Polyline(
                    points: route,
                    strokeWidth: 5,
                    color: Colors.blueAccent.withOpacity(0.9),
                    pattern: StrokePattern.dashed(segments: [12, 8]),
                    borderStrokeWidth: 1.5,
                    borderColor: (isDark ? Colors.black : Colors.white).withOpacity(0.6),
                  ),
                ],
              );
            }),

            /// MARKERS
            Obx(() {
              final validDevices = controller.devices.where((d) => d.latitude != 0 && d.longitude != 0).toList();

              if (validDevices.isEmpty) return const SizedBox();

              if (!_initialCameraSet) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _setInitialZoom(validDevices);
                });
                _initialCameraSet = true;
              }

              return MarkerLayer(
                markers: validDevices.map((d) {
                  final isSelected = _selectedDeviceId == d.id;

                  return Marker(
                    width: 90,
                    height: 70,
                    point: LatLng(d.latitude, d.longitude),
                    // O ícone é o primeiro item da Column (rótulo do nome vem
                    // depois, abaixo dele) — ancora o ponto geográfico no
                    // topo do widget, senão o flutter_map centraliza o bloco
                    // inteiro (ícone + rótulo) no ponto, e o ícone acaba
                    // desenhado acima da coordenada real / ponta da trilha.
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedDeviceId != d.id) controller.clearRoute();
                        setState(() {
                          _selectedDeviceId = d.id;
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.rotate(
                            angle: d.heading * (pi / 180),
                            child: _VehicleMarker(isActive: d.ignition, isSelected: isSelected),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              d.name,
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),

            /// ATRIBUIÇÃO (obrigatória pelos termos do Mapbox)
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('© Mapbox', onTap: () => launchUrlString('https://www.mapbox.com/about/maps/')),
                TextSourceAttribution('© OpenStreetMap', onTap: () => launchUrlString('https://www.openstreetmap.org/copyright')),
              ],
            ),
          ],
        ),

        /// TROCAR VEÍCULO (um por um)
        Positioned(
          top: 16,
          right: 16,
          child: _MapButton(icon: Icons.swap_horiz, onTap: _selectNextDevice),
        ),

        /// BALÃO DE FILTRO (ex.: "motos do cliente X") — some ao tocar no x.
        Positioned(
          top: 16,
          left: 16,
          right: 76,
          child: Obx(() {
            final label = controller.filterLabel.value;
            if (label == null) return const SizedBox.shrink();

            return _FilterBadge(label: label, onClear: _clearFilter);
          }),
        ),

        /// CONTROLES + CARD num único bloco — nunca um por trás do outro,
        /// porque crescem juntos na mesma Column em vez de Positioned soltos.
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Obx(() {
            final device = controller.devices.firstWhereOrNull((d) => d.id == _selectedDeviceId);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (device != null) ...[
                      _MapButton(icon: Icons.visibility, onTap: () => _openDetails(device)),
                      const SizedBox(width: 10),
                      _MapButton(icon: device.blocked == true ? Icons.lock : Icons.lock_open, onTap: () => _toggleLock(device)),
                      const SizedBox(width: 10),
                    ],
                    _MapButton(icon: Icons.my_location, onTap: _centerMap),
                    const SizedBox(width: 10),
                    _MapButton(
                      icon: _followVehicle ? Icons.gps_fixed : Icons.gps_not_fixed,
                      onTap: () {
                        setState(() => _followVehicle = !_followVehicle);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    final slide = Tween(begin: const Offset(0, 1), end: Offset.zero).animate(animation);

                    return SlideTransition(
                      position: slide,
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: device == null
                      ? const SizedBox()
                      : GestureDetector(
                          key: ValueKey(device.id),
                          onTap: () => _openDetails(device),
                          child: _VehicleInfoCard(
                            device: device,
                            isTracingRoute: controller.isTracingRoute.value,
                            hasRoute: controller.routeToDevice.value != null,
                            onTraceRoute: () => _traceRoute(device),
                            onClearRoute: controller.clearRoute,
                          ),
                        ),
                ),
              ],
            );
          }),
        ),
      ],
    );

    if (widget.height != null) {
      return SizedBox(height: widget.height, child: stack);
    }
    return stack;
  }

  void _clearFilter() {
    controller.clearFilter();
    setState(() => _initialCameraSet = false);
  }

  void _centerMap() {
    if (controller.devices.isEmpty) return;

    final d = controller.devices.first;

    mapController.move(LatLng(d.latitude, d.longitude), 17);
  }

  /// Vai selecionando os veículos um por um (ordem da lista, com wrap-around).
  void _selectNextDevice() {
    final list = controller.devices;
    if (list.isEmpty) return;

    final currentIndex = list.indexWhere((d) => d.id == _selectedDeviceId);
    final next = list[(currentIndex + 1) % list.length];

    controller.clearRoute();
    setState(() => _selectedDeviceId = next.id);
    mapController.move(LatLng(next.latitude, next.longitude), 17);
  }

  void _openDetails(DevicePosition device) {
    final vehicle = controller.vehicle.list.firstWhereOrNull((d) => d.id == device.id);
    if (vehicle == null) return;

    Get.toNamed(Routes.VEHICLE_DETAILS, arguments: vehicle);
  }

  Future<void> _traceRoute(DevicePosition device) async {
    await controller.traceRouteTo(device);

    final error = controller.routeError.value;
    if (error != null) {
      Get.snackbar('Rota', error);
    }
  }

  void _toggleLock(DevicePosition device) {
    final blocked = device.blocked;

    if (blocked == null) {
      EngineActionModal.show(
        context: context,
        onEngineOn: () => controller.toggleLock(device.id, block: false),
        onEngineOff: () => controller.toggleLock(device.id, block: true),
      );
      return;
    }

    GenericModalMolecule.show(
      context: context,
      isDanger: !blocked,
      icon: blocked ? Icons.lock_open : Icons.lock,
      title: blocked ? 'Desbloquear veículo' : 'Bloquear veículo',
      description: blocked ? 'Deseja liberar o veículo?' : 'Deseja BLOQUEAR o veículo? Isso pode desligá-lo remotamente.',
      successTextButton: blocked ? 'Desbloquear' : 'Bloquear',
      secondyTextButton: 'Cancelar',
      primaryMethod: () => controller.toggleLock(device.id, block: !blocked),
      secondyMethod: () {},
    );
  }

  void _setInitialZoom(List validDevices) {
    if (validDevices.isEmpty) return;

    if (validDevices.length == 1) {
      final d = validDevices.first;
      mapController.move(LatLng(d.latitude, d.longitude), 17);
    } else {
      final points = validDevices.map((d) => LatLng(d.latitude, d.longitude)).toList();

      final bounds = LatLngBounds.fromPoints(points);

      mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
    }
  }
}

/// BALÃO DE FILTRO
class _FilterBadge extends StatelessWidget {
  final String label;
  final VoidCallback onClear;

  const _FilterBadge({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(100),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 6, bottom: 6, right: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            IconButton(
              tooltip: 'Voltar à visualização padrão',
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}

/// MARKER
class _VehicleMarker extends StatelessWidget {
  final bool isActive;
  final bool isSelected;

  const _VehicleMarker({required this.isActive, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.gray;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      transform: Matrix4.identity()..scale(isSelected ? 1.2 : 1.0),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: [BoxShadow(blurRadius: isSelected ? 16 : 8, color: Colors.black.withOpacity(0.3))],
      ),
      child: Icon(Icons.navigation_rounded, color: color, size: 20),
    );
  }
}

/// CARD
class _VehicleInfoCard extends StatelessWidget {
  final dynamic device;
  final bool isTracingRoute;
  final bool hasRoute;
  final VoidCallback onTraceRoute;
  final VoidCallback onClearRoute;

  const _VehicleInfoCard({
    super.key,
    required this.device,
    required this.isTracingRoute,
    required this.hasRoute,
    required this.onTraceRoute,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = device.ignition == true;

    return Material(
      borderRadius: BorderRadius.circular(20),
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Theme.of(context).cardColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: (isOn ? AppColors.success : AppColors.gray).withOpacity(0.15),
                  child: Icon(Icons.directions_car_rounded, color: isOn ? AppColors.success : AppColors.gray),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                StatusBadge(
                  icon: Icons.battery_charging_full,
                  color: device.charge == null ? null : (device.charge == true ? AppColors.success : AppColors.error),
                ),
                const SizedBox(width: 8),
                StatusBadge(
                  icon: device.blocked == true ? Icons.lock : Icons.lock_open,
                  color: device.blocked == null ? null : (device.blocked == true ? AppColors.error : AppColors.success),
                ),
                const SizedBox(width: 8),
                Text(
                  isOn ? 'ON' : 'OFF',
                  style: TextStyle(color: isOn ? AppColors.success : AppColors.gray, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_InfoItem(label: 'Distância', value: '${(device.totalDistance / 1000).toStringAsFixed(2)} km')],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareLocation,
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Compartilhar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isTracingRoute ? null : (hasRoute ? onClearRoute : onTraceRoute),
                    icon: isTracingRoute
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(hasRoute ? Icons.close_rounded : Icons.directions_rounded, size: 18),
                    label: Text(hasRoute ? 'Limpar rota' : 'Traçar rota'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareLocation() {
    final link = 'https://www.google.com/maps?q=${device.latitude},${device.longitude}';
    SharePlus.instance.share(ShareParams(text: 'Localização de ${device.name}: $link'));
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// BOTÃO — circular, no padrão de FAB de apps de mapa modernos (Google
/// Maps/Uber), com o ícone na cor de destaque da marca.
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: AppColors.primary, size: 22)),
      ),
    );
  }
}
