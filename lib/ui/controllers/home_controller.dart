import 'dart:async';

import 'package:app_tracking/app/services/reverse_geocode_service.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/position_event_handler.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final TraccarService traccarService;
  final ReverseGeocodeService geocodeService;
  final VehicleState vehicles;

  final TraccarWebSocketService socketService;
  final PositionEventHandler eventHandler;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Timer? _timer;

  HomeController({
    required this.traccarService,
    required this.geocodeService,
    required this.vehicles,
    required this.socketService,
    required this.eventHandler,
  });

  @override
  void onInit() async {
    super.onInit();
    await _init();
    _connectSocket();
  }

  @override
  void onClose() {
    _timer?.cancel();
    socketService.disconnect();
    super.onClose();
  }

  // =======================
  // SOCKET
  // =======================

  void _connectSocket() {
    if (socketService.isConnected) return;

    socketService.connect(
      sessionId: traccarService.jsessionId!,
      onData: _onSocketData,
      onError: (e) => print('WS erro: $e'),
    );
  }

  void _onSocketData(Map<String, dynamic> data) {
    final positions = data['positions'];
    if (positions == null) return;

    for (final pos in positions) {
      final deviceId = pos['deviceId'];
      final index = vehicles.list.indexWhere((d) => d.id == deviceId);
      if (index == -1) continue;
      final attrs = pos['attributes'] ?? {};

      vehicles.deviceUpdate(index, attrs);
      eventHandler.handle(deviceId, attrs);
      vehicles.list.refresh();
    }
  }

  // =======================
  // INIT
  // =======================

  Future<void> _init() async {
    await loadDevices();
    // _timer = Timer.periodic(const Duration(seconds: 30), (_) => refreshStatus());
  }

  // =======================
  // DEVICES
  // =======================

  Future<void> loadDevices() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final list = await traccarService.getDevices();
      vehicles.list.assignAll(list.map<DeviceModel>((e) => DeviceModel.fromJson(e as Map<String, dynamic>)));

      await refreshStatus();
    } catch (e) {
      errorMessage.value = 'Erro ao carregar dispositivos';
    } finally {
      isLoading.value = false;
    }
  }

  // =======================
  // STATUS
  // =======================

  Future<void> refreshStatus() async {
    print('Refresh start');
    try {
      final positions = await traccarService.getLastPositions();

      vehicles.positionsInfo(positions);
      isLoading.value = false;
      await loadAddresses(vehicles.list, positions);
      print('refresh done');
    } catch (e) {
      print(e);
      errorMessage.value = 'Erro ao atualizar status';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAddresses(List<DeviceModel> devicesList, Map<int, dynamic> positions) async {
    for (int i = 0; i < devicesList.length; i++) {
      final device = devicesList[i];
      final position = positions[device.id];

      if (position == null) continue;
      if (device.attributes.address != null && device.attributes.address!.isNotEmpty) continue;
      final lat = position['latitude'];
      final lon = position['longitude'];

      if (lat == null || lon == null) continue;

      final address = await geocodeService.getAddress(lat, lon);

      devicesList[i] = device.copyWith(attributes: device.attributes.copyWith(address: address));
    }
    vehicles.list.refresh();
  }

  // =======================
  // COMMANDS
  // =======================

  Future<bool> sendCommand(int deviceId, String command) async {
    try {
      return await traccarService.sendCommand(deviceId, command);
    } catch (_) {
      errorMessage.value = 'Erro ao enviar comando';
      return false;
    }
  }
}
