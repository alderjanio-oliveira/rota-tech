import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/traccar_socket_service.dart';
import 'package:app_tracking/ui/model/positiion_model.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class MapCustomController extends GetxController {
  final TraccarService traccarService;
  final TraccarWebSocketService socketService;

  MapCustomController(this.traccarService, this.socketService);

  final devices = <DevicePosition>[].obs;
  final loading = false.obs;

  int? _deviceId;

  /// Callback para avisar o widget que posição mudou
  Function(LatLng position)? onPositionUpdated;

  @override
  void onClose() {
    socketService.disconnect();
    super.onClose();
  }

  // 🔥 inicialização correta
  void init({int? deviceId}) {
    _deviceId = deviceId;
    loadDevices();
    _connectSocket();
  }

  // ===============================
  // CARREGAR POSIÇÕES INICIAIS
  // ===============================
  Future<void> loadDevices() async {
    loading.value = true;

    try {
      final positions = await traccarService.getAllPositions();

      final list = positions.map<DevicePosition>((p) {
        return DevicePosition(
          id: p['deviceId'],
          name: p['deviceName'] ?? 'Sem Nome',
          latitude: (p['latitude'] as num).toDouble(),
          longitude: (p['longitude'] as num).toDouble(),
          ignition: p['attributes']?['ignition'] ?? false,
          totalDistance: (p['attributes']?['totalDistance'] ?? 0).toDouble(),
          heading: (p['course'] ?? 0).toDouble(),
        );
      }).toList();

      if (_deviceId != null) {
        devices.value = list.where((d) => d.id == _deviceId).toList();
      } else {
        devices.value = list;
      }
    } finally {
      loading.value = false;
    }
  }

  // ===============================
  // SOCKET
  // ===============================
  void _connectSocket() {
    socketService.connect(sessionId: traccarService.jsessionId!, onData: _onSocketData);
  }

  void _onSocketData(Map<String, dynamic> data) {
    if (data['positions'] == null) return;

    for (var pos in data['positions']) {
      final deviceId = pos['deviceId'];

      final index = devices.indexWhere((d) => d.id == deviceId);

      if (index == -1) continue;

      final newLat = (pos['latitude'] as num).toDouble();
      final newLng = (pos['longitude'] as num).toDouble();

      // evita rebuild desnecessário
      if (devices[index].latitude == newLat && devices[index].longitude == newLng) {
        continue;
      }

      final updated = devices[index].copyWith(
        latitude: newLat,
        longitude: newLng,
        heading: (pos['course'] ?? 0).toDouble(),
        ignition: pos['attributes']?['ignition'] ?? false,
      );

      devices[index] = updated;

      // 🔥 avisa o widget
      if (devices.length == 1) {
        onPositionUpdated?.call(LatLng(updated.latitude, updated.longitude));
      }
    }
  }
}
