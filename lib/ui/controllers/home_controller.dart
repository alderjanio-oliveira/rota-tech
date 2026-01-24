import 'dart:async';

import 'package:app_tracking/app/services/reverse_geocode_service.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/position_event_handler.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final TraccarService traccarService;
  final ReverseGeocodeService geocodeService;

  late final TraccarWebSocketService socketService;
  late final PositionEventHandler eventHandler;

  final RxList<DeviceModel> devices = <DeviceModel>[].obs;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  Timer? _timer;

  HomeController({required this.traccarService, required this.geocodeService});

  @override
  void onInit() async {
    super.onInit();
    await _init();
    socketService = Get.find();
    eventHandler = Get.find();
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

    socketService.connect(sessionId: traccarService.jsessionId!, onData: _onSocketData, onError: (e) => print('WS erro: $e'));
  }

  void _onSocketData(Map<String, dynamic> data) {
    final positions = data['positions'];
    if (positions == null) return;

    for (final pos in positions) {
      final deviceId = pos['deviceId'];
      final attrs = pos['attributes'] ?? {};

      final index = devices.indexWhere((d) => d.id == deviceId);
      if (index == -1) continue;

      final device = devices[index];

      final updatedAttributes = device.attributes.copyWith(
        ignition: attrs['ignition'] ?? attrs['motion'],
        lockState: attrs['blocked'] ?? device.attributes.lockState,
        charge: attrs['charge'] ?? device.attributes.charge,
        totalDistance: attrs['totalDistance']?.toDouble() ?? device.attributes.totalDistance,
      );

      devices[index] = device.copyWith(attributes: updatedAttributes);

      eventHandler.handle(deviceId, attrs);
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
      devices.assignAll(list.map<DeviceModel>((e) => DeviceModel.fromJson(e as Map<String, dynamic>)));

      await refreshStatus();
    } catch (_) {
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

      for (var i = 0; i < devices.length; i++) {
        final device = devices[i];
        final position = positions[device.id];
        if (position == null) continue;

        final attrs = position['attributes'] ?? {};

        var updatedDevice = device.copyWith(
          attributes: device.attributes.copyWith(
            ignition: attrs['ignition'] ?? attrs['motion'],
            lockState: attrs['blocked'] ?? device.attributes.lockState,
            charge: attrs['charge'] ?? device.attributes.charge,
            totalDistance: attrs['totalDistance']?.toDouble() ?? device.attributes.totalDistance,
          ),
          lastPositionId: position['id'],
        );

        devices[i] = updatedDevice;
      }
      isLoading.value = false;
      await loadAddresses(devices, positions);
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
    devices.refresh();
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
