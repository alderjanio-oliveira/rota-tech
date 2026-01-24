import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/ui/model/positiion_model.dart';
import 'package:get/get.dart';

class MapCustomController extends GetxController {
  final TraccarService traccarService;

  MapCustomController(this.traccarService);

  var devices = <DevicePosition>[].obs;
  var loading = false.obs;

  /// Para exibir apenas um
  DevicePosition? selectedDevice;

  Future<void> loadDevices({int? deviceId}) async {
    loading.value = true;

    try {
      final positions = await traccarService.getAllPositions();

      final list = positions.map((p) {
        return DevicePosition(
          id: p['deviceId'],
          name: p['deviceName'] ?? 'Sem Nome',
          latitude: p['latitude'],
          longitude: p['longitude'],
          ignition: p['attributes']?['ignition'] ?? false,
          totalDistance: p['attributes']?['totalDistance'] ?? 0,
        );
      }).toList();

      if (deviceId != null) {
        selectedDevice = list.firstWhere((d) => d.id == deviceId, orElse: () => list.first);
        devices.value = [selectedDevice!];
      } else {
        devices.value = list;
      }
    } finally {
      loading.value = false;
    }
  }
}
