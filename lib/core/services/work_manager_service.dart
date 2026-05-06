import 'package:app_tracking/app/services/reverse_geocode_service.dart';
import 'package:app_tracking/app/services/vehicle_services.dart';
import 'package:app_tracking/core/services/api_helper.dart';
import 'package:app_tracking/core/services/auth_service.dart';
import 'package:app_tracking/core/services/auth_storage_service.dart';
import 'package:app_tracking/core/services/notification_service.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await GetStorage.init();
    await dotenv.load();

    if (task == Constants.taskTripAlert) {
      final AuthStorageService authStorageService = AuthStorageService();
      if (!(await canAutoLogin(authStorageService))) return Future.value(true);
      final session = UserSessionService();
      final AuthService authService = AuthService(
        session: session,
        apiHelper: ApiHelper(session: session),
      );
      if (!(await login(authStorageService, authService))) return Future.value(true);
      // final TraccarService traccarService = TraccarService();
      final ReverseGeocodeService geocodeService = ReverseGeocodeService();
      final VehicleServices vehicleServices = VehicleServices(
        session: session,
        geocodeService: geocodeService,
      );
      VehicleState vehicleState = VehicleState(vehicleServices: vehicleServices);
      await vehicleState.load();
      // final list = await traccarService.getDevices();
      // vehicleState.list.assignAll(list.map<DeviceModel>((e) => DeviceModel.fromJson(e as Map<String, dynamic>)));
      // final positions = await traccarService.getLastPositions();
      // vehicleState.positionsInfo(positions);
      String allDevicesInfo = '';
      for (final device in vehicleState.list) {
        if (device.attributes.charge != null && !device.attributes.charge!) {
          final notificationService = NotificationService();
          await notificationService.show(
            title: "Bateria desconectada 🔌",
            body: "Veículo ${device.name} teve a bateria desconectada.",
            id: device.id,
            payload: allDevicesInfo,
          );
        }
        if (device.attributes.trip == null || device.attributes.totalDistance == null) continue;
        if (device.tripKm == null) continue;
        if (device.tripReachedTarget) allDevicesInfo += 'Veículo ${device.name} atingiu ${device.tripKm!.toStringAsFixed(2)} KM.\n';
      }
      if (allDevicesInfo.isEmpty) return Future.value(true);
      final notificationService = NotificationService();
      await notificationService.init();

      await notificationService.show(
        title: "Trip atingido 🚗",
        body: allDevicesInfo,
        id: 1,
        payload: allDevicesInfo,
      );
    }

    return Future.value(true);
  });
}

Future<bool> canAutoLogin(AuthStorageService authStorageService) async {
  return await authStorageService.rememberMe() &&
      await authStorageService.getEmail() != null &&
      await authStorageService.getPassword() != null;
}

Future<bool> login(AuthStorageService authStorageService, AuthService authService) async {
  final email = await authStorageService.getEmail();
  final password = await authStorageService.getPassword();
  final success = await authService.login(email!, password!);
  return success;
}
