import 'package:app_tracking/app/services/vehicle_services.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/ui/model/positiion_model.dart';
import 'package:get/get.dart';

class VehicleState {
  final VehicleServices vehicleServices;
  final RxList<DeviceModel> list = <DeviceModel>[].obs;
  final RxList<DevicePosition> positions = <DevicePosition>[].obs;

  VehicleState({
    required this.vehicleServices,
  });

  onInit() {
    ever(list, (_) => print("Devices updated: ${list.length} devices"));
    ever(positions, (_) => print("Positions updated: ${positions.length} positions"));
  }

  Future<void> load() async {
    final getDevices = await vehicleServices.getDevices();
    list.assignAll(getDevices.map<DeviceModel>((e) => DeviceModel.fromJson(e as Map<String, dynamic>)));
    final getPositions = await vehicleServices.getLastPositions();
    positionsInfo(getPositions);
    await vehicleServices.loadAddresses(list, getPositions);
    list.refresh();
  }

  void deviceUpdate(int index, Map<String, dynamic> attrs) {
    final device = list[index];

    device.attributes.lockState.value = attrs['blocked'] ?? device.attributes.lockState.value;
    final updatedAttributes = device.attributes.copyWith(
      ignition: attrs['ignition'] ?? attrs['motion'],
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

      list[i].attributes.lockState.value = attrs['blocked'] ?? list[i].attributes.lockState.value;
      var updatedDevice = device.copyWith(
        attributes: device.attributes.copyWith(
          ignition: attrs['ignition'] ?? attrs['motion'],
          charge: attrs['charge'] ?? device.attributes.charge,
          totalDistance: attrs['totalDistance']?.toDouble() ?? device.attributes.totalDistance,
        ),
        lastPositionId: position['id'],
      );
      list[i] = updatedDevice;
    }
  }
}
