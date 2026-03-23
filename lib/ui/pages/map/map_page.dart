import 'dart:math';
import 'package:app_tracking/ui/controllers/map_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class MapWidget extends StatefulWidget {
  final int? deviceId;
  final double height;

  const MapWidget({super.key, this.deviceId, this.height = 300});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final controller = Get.find<MapCustomController>();
  final MapController mapController = MapController();

  bool _initialCameraSet = false;
  bool _followVehicle = true;

  @override
  void initState() {
    super.initState();

    controller.init(deviceId: widget.deviceId);

    controller.onPositionUpdated = (position) {
      if (_followVehicle && controller.devices.length == 1) {
        mapController.move(position, mapController.camera.zoom);
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          /// 🗺️ MAPA
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(),
            children: [
              /// 🔥 TILE PROFISSIONAL (COM OVERLAY)
              TileLayer(
                urlTemplate: 'https://api.maptiler.com/maps/bright-v2/{z}/{x}/{y}.png?key=xvu6cMMOUoNcxzaLO3IE',
                userAgentPackageName: 'com.example.app_tracking',
              ),

              /// 🌙 DARK OVERLAY (CORRETO)
              if (isDark) Container(color: Colors.black.withOpacity(0.35)),

              /// 🔵 TRILHAS
              Obx(() {
                if (controller.trails.isEmpty) return const SizedBox();

                return PolylineLayer(
                  polylines: controller.trails.entries
                      .where((e) => e.value.isNotEmpty)
                      .map(
                        (e) => Polyline(
                          points: e.value,
                          strokeWidth: 4,
                          color: Colors.blueAccent.withOpacity(0.8),
                        ),
                      )
                      .toList(),
                );
              }),

              /// 🚗 MARKERS
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
                    return Marker(
                      width: 36,
                      height: 36,
                      point: LatLng(d.latitude, d.longitude),

                      child: Transform.rotate(
                        // 🔥 CORREÇÃO REAL DO HEADING
                        angle: (d.heading + 90) * (pi / 180),
                        child: _VehicleMarker(isActive: d.ignition),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),

          /// 🎮 CONTROLES
          Positioned(
            right: 16,
            bottom: 120,
            child: Column(
              children: [
                _MapButton(
                  icon: Icons.my_location,
                  onTap: _centerMap,
                ),
                const SizedBox(height: 10),
                _MapButton(
                  icon: _followVehicle ? Icons.gps_fixed : Icons.gps_not_fixed,
                  onTap: () {
                    setState(() => _followVehicle = !_followVehicle);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _centerMap() {
    if (controller.devices.isEmpty) return;

    final d = controller.devices.first;

    mapController.move(
      LatLng(d.latitude, d.longitude),
      17,
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

      mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50),
        ),
      );
    }
  }
}

/// 🚗 MARKER MELHORADO
class _VehicleMarker extends StatelessWidget {
  final bool isActive;

  const _VehicleMarker({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.green : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withOpacity(0.3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Icon(
        Icons.navigation_rounded,
        color: color,
        size: 20,
      ),
    );
  }
}

/// 🔘 BOTÃO MAPA
class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon),
        ),
      ),
    );
  }
}
