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

  /// Carrega devices, posição e endereço em sequência. Para telas que
  /// queiram exibir os cards antes (skeleton) chame [loadDevices] e
  /// [loadPositionsAndAddresses] separadamente, como o HomeController faz.
  Future<void> load() async {
    await loadDevices();
    await loadPositionsAndAddresses();
  }

  /// Busca só a lista de devices, para a tela poder exibir os cards
  /// (em skeleton) o quanto antes, sem esperar posição/endereço.
  Future<void> loadDevices() async {
    final getDevices = await vehicleServices.getDevices();
    list.assignAll(getDevices.map<DeviceModel>((e) => DeviceModel.fromJson(e as Map<String, dynamic>)));
  }

  /// Preenche posição e endereço depois que os devices já estão na tela.
  /// O endereço é resolvido card a card, atualizando a lista a cada um
  /// pronto, em vez de travar tudo até o último terminar.
  Future<void> loadPositionsAndAddresses() async {
    final getPositions = await vehicleServices.getLastPositions();
    positionsInfo(getPositions);
    await _loadAddressesProgressively(getPositions);
  }

  Future<void> _loadAddressesProgressively(Map<int, dynamic> positions) async {
    for (final device in List<DeviceModel>.from(list)) {
      final position = positions[device.id];
      if (position == null) continue;
      if (device.attributes.address != null && device.attributes.address!.isNotEmpty) continue;

      final lat = position['latitude'];
      final lon = position['longitude'];
      if (lat == null || lon == null) continue;

      final address = await vehicleServices.geocodeService.getAddress(lat, lon);
      if (address == null) continue;

      final index = list.indexWhere((d) => d.id == device.id);
      if (index == -1) continue;
      list[index] = list[index].copyWith(attributes: list[index].attributes.copyWith(address: address));
    }
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
      if (position == null) {
        list[i] = device.copyWith(positionLoaded: true);
        continue;
      }

      final attrs = position['attributes'] ?? {};

      list[i].attributes.lockState.value = attrs['blocked'] ?? list[i].attributes.lockState.value;
      var updatedDevice = device.copyWith(
        attributes: device.attributes.copyWith(
          ignition: attrs['ignition'] ?? attrs['motion'],
          charge: attrs['charge'] ?? device.attributes.charge,
          totalDistance: attrs['totalDistance']?.toDouble() ?? device.attributes.totalDistance,
        ),
        lastPositionId: position['id'],
        positionLoaded: true,
      );
      list[i] = updatedDevice;
    }
  }
}
