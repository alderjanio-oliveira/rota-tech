import 'dart:async';

import 'package:app_tracking/app/services/reverse_geocode_service.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/notification_service.dart';
import 'package:app_tracking/core/services/position_event_handler.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/utils/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  final TraccarService traccarService;
  final ReverseGeocodeService geocodeService;
  final VehicleState vehicles;
  final UserSessionService session;

  final TraccarWebSocketService socketService;
  final PositionEventHandler eventHandler;

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// Alterna entre a lista de devices e o mapa na Home. Persistido em disco
  /// pra continuar no mesmo modo mesmo se o controller for recriado (app
  /// fechado/reaberto).
  final _storage = GetStorage();
  late final RxBool isMapView = (_storage.read<bool>(Constants.homeViewModeKey) ?? false).obs;

  /// Texto de busca — filtra a lista e, quando casa com um único device,
  /// centraliza o mapa nele.
  final RxString search = ''.obs;
  final TextEditingController searchController = TextEditingController();

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
    WidgetsBinding.instance.addObserver(this);
    await _init();
    _connectSocket();
    NotificationService.openPendingNavigation();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    socketService.disconnect();
    searchController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.openPendingNavigation();
    }
  }

  void toggleMapView() {
    isMapView.value = !isMapView.value;
    _storage.write(Constants.homeViewModeKey, isMapView.value);
  }

  void clearSearch() {
    searchController.clear();
    search.value = '';
  }

  void selectSearchSuggestion(String deviceName) {
    searchController.text = deviceName;
    search.value = deviceName;
  }

  // =======================
  // SOCKET
  // =======================

  void _connectSocket() {
    socketService.connect(onData: _onSocketData, onError: (e) => print('WS erro: $e'));
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
      await vehicles.loadDevices();
      isLoading.value = false;

      // Posição e endereço continuam carregando com a lista já na tela
      // (cards em skeleton até cada um ser preenchido).
      await vehicles.loadPositionsAndAddresses();
    } catch (e) {
      errorMessage.value = 'Erro ao carregar dispositivos';
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
