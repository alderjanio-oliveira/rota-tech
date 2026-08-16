import 'dart:async';
import 'package:app_tracking/app/services/directions_service.dart';
import 'package:app_tracking/core/services/vehicle_motion_egine.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:geolocator/geolocator.dart';
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
  final DirectionsService _directionsService = DirectionsService();

  MapCustomController(this.traccarService, this.socketService, this.trackingConfig, this.vehicle);

  // ===============================
  // STATE
  // ===============================

  final devices = <DevicePosition>[].obs;
  final loading = false.obs;

  /// Trilhas por device — lista de TRECHOS (cada trecho é uma sequência
  /// contínua de pontos). Um hiato sem posição real (tela bloqueada, sem
  /// sinal) fecha o trecho atual e abre um novo, em vez de ligar os dois
  /// com uma linha reta cruzando o hiato.
  final trails = <int, List<List<LatLng>>>{}.obs;

  /// Motion engines por device
  final Map<int, VehicleMotionEngine> _motionEngines = {};

  /// Stream subscriptions por device
  final Map<int, StreamSubscription<MotionUpdate>> _motionSubscriptions = {};

  int? _deviceId;
  List<int>? _deviceIds;

  /// Nome exibido no balão de filtro (ex.: nome do cliente), quando o mapa
  /// está restrito aos devices de um usuário específico.
  final RxnString filterLabel = RxnString();

  /// Rota traçada da localização do usuário até o device selecionado. Fica
  /// parada (não recalcula) enquanto o veículo se move — a posição dele já
  /// atualiza sozinha no mapa, não precisa retraçar.
  final Rxn<List<LatLng>> routeToDevice = Rxn<List<LatLng>>();
  final RxBool isTracingRoute = false.obs;
  final RxnString routeError = RxnString();

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

      final list = positions.map<DevicePosition>((p) {
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
        trails[d.id] = [<LatLng>[]];
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

    _motionSubscriptions[deviceId] = _motionEngines[deviceId]!.stream.listen((update) {
      final index = devices.indexWhere((d) => d.id == deviceId);

      if (index == -1) return;

      final updated = devices[index].copyWith(
        latitude: update.position.latitude,
        longitude: update.position.longitude,
        heading: _lastHeading[deviceId] ?? devices[index].heading,
      );

      devices[index] = updated;

      _updateTrail(deviceId, update.position, newSegment: update.startsNewSegment);

      if (devices.length == 1) {
        onPositionUpdated?.call(update.position);
      }
    });
  }

  // ===============================
  // TRAIL MANAGEMENT
  // ===============================

  void _updateTrail(int deviceId, LatLng point, {required bool newSegment}) {
    if (trackingConfig.isDisabled) return;

    final segments = trails.putIfAbsent(deviceId, () => [<LatLng>[]]);

    if (newSegment || segments.isEmpty) {
      segments.add(<LatLng>[point]);
    } else {
      segments.last.add(point);
    }

    if (!trackingConfig.isInfinite && trackingConfig.usePoints) {
      _trimByPoints(segments);
    }

    trails.refresh();
  }

  /// Remove os pontos mais antigos (do trecho mais antigo) até caber no
  /// limite configurado, descartando trechos que ficarem vazios.
  void _trimByPoints(List<List<LatLng>> segments) {
    var total = segments.fold<int>(0, (sum, s) => sum + s.length);

    while (total > trackingConfig.value && segments.isNotEmpty) {
      final oldest = segments.first;

      if (oldest.isEmpty) {
        segments.removeAt(0);
        continue;
      }

      oldest.removeAt(0);
      total--;

      if (oldest.isEmpty) segments.removeAt(0);
    }
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
  // ROTA ATÉ O DEVICE
  // ===============================

  /// Traça a rota rodoviária da localização atual do usuário até o device.
  /// É uma "foto" única — não recalcula sozinha se o veículo se mover, já
  /// que a posição dele no mapa já atualiza em tempo real por conta própria.
  Future<void> traceRouteTo(DevicePosition device) async {
    routeError.value = null;

    try {
      isTracingRoute.value = true;

      final origin = await _getCurrentPosition();
      if (origin == null) {
        routeError.value = 'Não foi possível obter sua localização.';
        return;
      }

      final route = await _directionsService.getRoute(
        from: LatLng(origin.latitude, origin.longitude),
        to: LatLng(device.latitude, device.longitude),
      );

      if (route == null) {
        routeError.value = 'Não foi possível traçar a rota até o veículo.';
        return;
      }

      routeToDevice.value = route;
    } catch (e) {
      routeError.value = 'Erro ao traçar rota: $e';
    } finally {
      isTracingRoute.value = false;
    }
  }

  void clearRoute() {
    routeToDevice.value = null;
  }

  Future<Position?> _getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  // ===============================
  // PUBLIC API
  // ===============================

  List<List<LatLng>> getTrail(int deviceId) {
    return trails[deviceId] ?? [];
  }

  void clearTrail(int deviceId) {
    trails[deviceId] = [<LatLng>[]];
  }

  void clearAllTrails() {
    for (final deviceId in trails.keys.toList()) {
      trails[deviceId] = [<LatLng>[]];
    }
  }
}
