import 'dart:async';

import 'package:app_tracking/app/services/reverse_geocode_service.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/position_event_handler.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final TraccarService traccarService;
  final ReverseGeocodeService geocodeService;
  final VehicleState vehicles;
  final UserSessionService session;

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
    required this.session,
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

      if (vehicles.list[index].attributes.ignition != attrs['ignition']) {
        eventHandler.handle(deviceId, attrs, vehicles.list[index]);
      }
      vehicles.deviceUpdate(index, attrs);
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
      vehicles.load();
    } catch (e) {
      errorMessage.value = 'Erro ao carregar dispositivos';
    } finally {
      isLoading.value = false;
    }
  }

  // =======================
  // COMMANDS
  // =======================

  Future<void> sendCommand(int index, String command) async {
    vehicles.list[index].loading.value = true;
    final deviceId = vehicles.list[index].id;
    try {
      await traccarService.sendCommand(deviceId, command);
      vehicles.list[index].attributes.lockState.value = command == 'engineStop';
      vehicles.list.refresh();
    } catch (_) {
      errorMessage.value = 'Erro ao enviar comando';
    } finally {
      vehicles.list[index].loading.value = false;
    }
  }
}
