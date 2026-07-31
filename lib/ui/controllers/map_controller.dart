import 'dart:async';
import 'package:app_tracking/core/services/vehicle_motion_egine.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/core/config/map_tracking_config.dart';
import 'package:app_tracking/ui/model/positiion_model.dart';

class MapCustomController extends GetxController {
  final TraccarService traccarService;
  final TraccarWebSocketService socketService;
  final MapTrackingConfig trackingConfig;
  final VehicleState vehicle;

  MapCustomController(this.traccarService, this.socketService, this.trackingConfig, this.vehicle);

  // ===============================
  // STATE
  // ===============================

  final devices = <DevicePosition>[].obs;
  final loading = false.obs;

  /// Trilhas por device
  final trails = <int, RxList<LatLng>>{}.obs;

  /// Motion engines por device
  final Map<int, VehicleMotionEngine> _motionEngines = {};

  /// Stream subscriptions por device
  final Map<int, StreamSubscription<LatLng>> _motionSubscriptions = {};

  int? _deviceId;
  List<int>? _deviceIds;

  /// Nome exibido no balão de filtro (ex.: nome do cliente), quando o mapa
  /// está restrito aos devices de um usuário específico.
  final RxnString filterLabel = RxnString();

  /// Callback para mover câmera
  Function(LatLng position)? onPositionUpdated;

  final Map<int, double> _lastHeading = {};

  // ===============================
  // LIFECYCLE
  // ===============================

  @override
  void onClose() {
    socketService.removeListener(_onSocketData);

    for (var engine in _motionEngines.values) {
      engine.dispose();
    }

    for (var sub in _motionSubscriptions.values) {
      sub.cancel();
    }

    super.onClose();
  }

  // ===============================
  // INIT
  // ===============================

  void init({int? deviceId, List<int>? deviceIds, String? filterLabel}) {
    _deviceId = deviceId;
    _deviceIds = deviceIds;
    this.filterLabel.value = filterLabel;
    loadDevices();
    _connectSocket();
  }

  /// Volta pra visualização padrão (todos os devices).
  void clearFilter() {
    _deviceId = null;
    _deviceIds = null;
    filterLabel.value = null;
    loadDevices();
  }

  // ===============================
  // LOAD INITIAL POSITIONS
  // ===============================

  Future<void> loadDevices() async {
    loading.value = true;

    try {
      final positions = await traccarService.getAllPositions();

      final list =
          positions.map<DevicePosition>((p) {
            DeviceModel hasVehicle = vehicle.list.firstWhere((i) => i.id == p['deviceId']);
            return DevicePosition(
              id: p['deviceId'],
              name: hasVehicle.name,
              latitude: (p['latitude'] as num).toDouble(),
              longitude: (p['longitude'] as num).toDouble(),
              ignition: hasVehicle.attributes.ignition ?? p['attributes']?['ignition'] ?? p['attributes']?['motion'] ?? false,
              totalDistance: (p['attributes']?['totalDistance'] ?? 0).toDouble(),
              heading: (p['course'] ?? 0).toDouble(),
              charge: hasVehicle.attributes.charge ?? p['attributes']?['charge'] as bool?,
              blocked: hasVehicle.attributes.lockState.value ?? p['attributes']?['blocked'] as bool?,
            );
          }).toList();

      if (_deviceIds != null && _deviceIds!.isNotEmpty) {
        devices.value = list.where((d) => _deviceIds!.contains(d.id)).toList();
      } else if (_deviceId != null) {
        devices.value = list.where((d) => d.id == _deviceId).toList();
      } else {
        devices.value = list;
      }

      // Inicializa trilhas e engines
      for (var d in devices) {
        trails[d.id] = <LatLng>[].obs;
        _initializeMotionEngine(d.id);
      }
    } finally {
      loading.value = false;
    }
  }

  // ===============================
  // SOCKET
  // ===============================

  void _connectSocket() {
    socketService.connect(onData: _onSocketData);
  }

  void _onSocketData(Map<String, dynamic> data) {
    if (data['positions'] == null) return;

    for (var pos in data['positions']) {
      final deviceId = pos['deviceId'];

      final index = devices.indexWhere((d) => d.id == deviceId);

      if (index == -1) continue;

      // Bateria/bloqueio atualizam sempre, mesmo sem mudança de posição.
      // Reconstrói explícito (não via copyWith) pra aceitar volta a `null`,
      // que copyWith não conseguiria distinguir de "não informado".
      final attrs = pos['attributes'] ?? {};
      final charge = attrs['charge'] as bool?;
      final blocked = attrs['blocked'] as bool?;
      final current = devices[index];
      if (charge != current.charge || blocked != current.blocked) {
        devices[index] = DevicePosition(
          id: current.id,
          name: current.name,
          latitude: current.latitude,
          longitude: current.longitude,
          ignition: current.ignition,
          totalDistance: current.totalDistance,
          heading: current.heading,
          charge: charge,
          blocked: blocked,
        );
      }

      final newLat = (pos['latitude'] as num).toDouble();
      final newLng = (pos['longitude'] as num).toDouble();

      final heading = (pos['course'] ?? 0).toDouble();

      _lastHeading[deviceId] = heading;

      final speedKmh = pos['speed'] != null ? (pos['speed'] as num).toDouble() : null;

      if (devices[index].latitude == newLat && devices[index].longitude == newLng) {
        continue;
      }

      // Atualiza engine (NÃO atualiza device direto)
      _motionEngines[deviceId]?.updateRealPosition(newPosition: LatLng(newLat, newLng), heading: heading, speedKmh: speedKmh);
    }
  }

  // ===============================
  // MOTION ENGINE
  // ===============================

  void _initializeMotionEngine(int deviceId) {
    _motionEngines.putIfAbsent(deviceId, () => VehicleMotionEngine());

    _motionSubscriptions[deviceId] = _motionEngines[deviceId]!.stream.listen((predictedPosition) {
      final index = devices.indexWhere((d) => d.id == deviceId);

      if (index == -1) return;

      final updated = devices[index].copyWith(
        latitude: predictedPosition.latitude,
        longitude: predictedPosition.longitude,
        heading: _lastHeading[deviceId] ?? devices[index].heading,
      );

      devices[index] = updated;

      _updateTrail(deviceId, predictedPosition);

      if (devices.length == 1) {
        onPositionUpdated?.call(predictedPosition);
      }
    });
  }

  // ===============================
  // TRAIL MANAGEMENT
  // ===============================

  void _updateTrail(int deviceId, LatLng point) {
    if (trackingConfig.isDisabled) return;

    trails.putIfAbsent(deviceId, () => <LatLng>[].obs);

    final trail = trails[deviceId]!;

    trail.add(point);

    if (trackingConfig.isInfinite) return;

    if (trackingConfig.usePoints) {
      while (trail.length > trackingConfig.value) {
        trail.removeAt(0);
      }
    }

    if (trackingConfig.useTime) {
      _applyTimeLimit(deviceId);
    }
  }

  void _applyTimeLimit(int deviceId) {
    // Futuramente implementar com timestamp real
  }

  // ===============================
  // COMANDOS
  // ===============================

  /// Bloqueia/desbloqueia o veículo e, se o comando for aceito, já reflete o
  /// novo estado localmente (mesmo padrão otimista da lista).
  Future<void> toggleLock(int deviceId, {required bool block}) async {
    final index = devices.indexWhere((d) => d.id == deviceId);
    if (index == -1) return;

    final ok = await traccarService.sendCommand(deviceId, block ? 'engineStop' : 'engineResume');
    if (!ok) return;

    final current = devices[index];
    devices[index] = DevicePosition(
      id: current.id,
      name: current.name,
      latitude: current.latitude,
      longitude: current.longitude,
      ignition: current.ignition,
      totalDistance: current.totalDistance,
      heading: current.heading,
      charge: current.charge,
      blocked: block,
    );
  }

  // ===============================
  // PUBLIC API
  // ===============================

  List<LatLng> getTrail(int deviceId) {
    return trails[deviceId]?.toList() ?? [];
  }

  void clearTrail(int deviceId) {
    trails[deviceId]?.clear();
  }

  void clearAllTrails() {
    for (var trail in trails.values) {
      trail.clear();
    }
  }
}
