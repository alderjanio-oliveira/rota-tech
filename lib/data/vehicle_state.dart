import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/ui/model/positiion_model.dart';
import 'package:get/get.dart';

class VehicleState {
  final RxList<DeviceModel> list = <DeviceModel>[].obs;
  final RxList<DevicePosition> positions = <DevicePosition>[].obs;

  void deviceUpdate(int index, Map<String, dynamic> attrs) {
    final device = list[index];

    final updatedAttributes = device.attributes.copyWith(
      ignition: attrs['ignition'] ?? attrs['motion'],
      lockState: attrs['blocked'] ?? device.attributes.lockState,
      charge: attrs['charge'] ?? device.attributes.charge,
      totalDistance: attrs['totalDistance']?.toDouble() ?? device.attributes.totalDistance,
    );

    list[index] = device.copyWith(attributes: updatedAttributes);
  }

  void positionsInfo(positions) {
    for (var i = 0; i < list.length; i++) {
      final device = list[i];
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
      list[i] = updatedDevice;
    }
  }
}
