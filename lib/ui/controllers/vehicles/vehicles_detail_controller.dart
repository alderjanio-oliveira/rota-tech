import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/models/daily_distance.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleDetailsController extends GetxController {
  final TraccarService traccarService;
  final DeviceModel device;
  final VehicleState vehicleState;

  VehicleDetailsController({required this.traccarService, required this.device, required this.vehicleState});

  final RxBool isLoading = false.obs;

  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  final RxList<DailyDistance> dailyKmList = <DailyDistance>[].obs;
  final RxDouble dailyKm = 0.0.obs;
  final RxDouble totalKm = 0.0.obs;
  final TextEditingController target = TextEditingController();

  @override
  void onInit() {
    target.text = device.attributes.trip?.target?.toStringAsFixed(2) ?? '';
    tripCalculate();
    super.onInit();
  }

  Future<void> pickStartDate() async {
    startDate.value = await _pickDate();
  }

  Future<void> pickEndDate() async {
    endDate.value = await _pickDate();
  }

  Future<DateTime?> _pickDate() async {
    return await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
  }

  Future<void> searchKmByPeriod() async {
    dailyKm.value = await traccarService.getDailyDistance(deviceId: device.id, day: DateTime.now()) ?? 0.0;
    if (startDate.value == null || endDate.value == null) return;

    isLoading.value = true;

    dailyKmList.value = await traccarService.getDistanceByDay(deviceId: device.id, from: startDate.value!, to: endDate.value!);
    totalKm.value = dailyKmList.fold(0.0, (sum, item) => sum + item.km);

    isLoading.value = false;
  }

  tripCalculate() {
    if (device.attributes.trip?.offset == null) {
      return 0.0;
    }
    var tripCaulated = (device.attributes.totalDistance! - device.attributes.trip!.offset) / 1000;

    return tripCaulated;
  }

  get trip => device.attributes.trip?.offset == null ? null : ((device.attributes.totalDistance! - device.attributes.trip!.offset) / 1000);

  get tripFormatted => trip == null ? '0.00' : trip.toStringAsFixed(2);

  Future<void> resetTip(String trip, double target) async {
    await traccarService.updateDeviceTrip(
      device: device,
      tripKey: trip,
      offset: device.attributes.totalDistance ?? 0.0,
      target: target,
    );
  }
}
