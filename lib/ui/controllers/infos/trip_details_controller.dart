import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:get/get.dart';

class TripDetailsController extends GetxController {
  final VehicleState vehicle;
  TripDetailsController(this.vehicle);
  var listByKms = <DeviceModel>[].obs;

  loadDevices() {
    for (final device in vehicle.list) {
      if (device.attributes.trip == null || device.attributes.totalDistance == null) continue;

      if (device.tripKm == null && device.tripKm! < 50) continue;
      // allDevicesInfo += 'Veículo ${device.name} atingiu ${device.tripKm.toStringAsFixed(2)} KM.\n';
      // if (device.tripKm >= device.attributes.trip!.target!) {}
    }
  }
}
