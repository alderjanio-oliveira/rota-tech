import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/ui/models/daily_distance.dart';
import 'package:app_tracking/ui/models/daily_km_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VehicleDetailsController extends GetxController {
  final TraccarService traccarService;
  final int deviceId;

  VehicleDetailsController({required this.traccarService, required this.deviceId});

  final RxBool isLoading = false.obs;

  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  final RxList<DailyDistance> dailyKmList = <DailyDistance>[].obs;
  final RxDouble dailyKm = 0.0.obs;
  final RxDouble totalKm = 0.0.obs;

  Future<void> pickStartDate() async {
    startDate.value = await _pickDate();
  }

  Future<void> pickEndDate() async {
    endDate.value = await _pickDate();
  }

  Future<DateTime?> _pickDate() async {
    return await showDatePicker(context: Get.context!, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
  }

  Future<void> searchKmByPeriod() async {
    dailyKm.value = await traccarService.getDailyDistance(deviceId: deviceId, day: DateTime.now()) ?? 0.0;
    if (startDate.value == null || endDate.value == null) return;

    isLoading.value = true;

    dailyKmList.value = await traccarService.getDistanceByDay(deviceId: deviceId, from: startDate.value!, to: endDate.value!);
    totalKm.value = dailyKmList.fold(0.0, (sum, item) => sum + item.km);

    isLoading.value = false;
  }
}
