import 'package:app_tracking/app/services/reverse_geocode_service.dart';
import 'package:app_tracking/app/services/vehicle_services.dart';
import 'package:app_tracking/core/services/api_helper.dart';
import 'package:app_tracking/core/services/app_notification_store.dart';
import 'package:app_tracking/core/services/auth_service.dart';
import 'package:app_tracking/core/services/auth_storage_service.dart';
import 'package:app_tracking/core/services/notification_service.dart';
import 'package:app_tracking/core/services/notication_config_service.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/model/app_notification_model.dart';
import 'package:app_tracking/ui/model/notification_config_model.dart';
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
      final authStorageService = AuthStorageService();
      if (!(await canAutoLogin(authStorageService))) return Future.value(true);

      final session = UserSessionService();
      final authService = AuthService(session: session, apiHelper: ApiHelper(session: session));
      if (!(await login(authStorageService, authService))) return Future.value(true);

      final vehicleServices = VehicleServices(session: session, geocodeService: ReverseGeocodeService());
      final vehicleState = VehicleState(vehicleServices: vehicleServices);
      await vehicleState.load();

      final configJson = NoticationConfigService().getNotificationConfig();
      final config =
          configJson == null ? NotificationConfigModel() : NotificationConfigModel.fromJson(Map<String, dynamic>.from(configJson));
      if (!config.isEnabled) {
        await scheduleNextTripAlert(hasNearTargetVehicle: false);
        return Future.value(true);
      }

      final notificationService = NotificationService();
      await notificationService.init();

      final notificationStore = AppNotificationStore();
      final activeTripAlerts = await notificationStore.activeTripAlerts();
      final mutedDeviceAlerts = await notificationStore.mutedDeviceAlerts();
      final nextActiveTripAlerts = <int>{};
      final tripMessages = <String>[];

      var hasNearTargetVehicle = false;

      for (final device in vehicleState.list) {
        if (mutedDeviceAlerts.contains(device.id)) continue;

        if (config.chargeAlert && device.attributes.charge != null && !device.attributes.charge!) {
          final notification = AppNotificationModel(
            id: 'charge-${device.id}-${DateTime.now().millisecondsSinceEpoch}',
            type: 'charge',
            title: 'Bateria desconectada',
            body: 'Veículo ${device.name} teve a bateria desconectada.',
            createdAt: DateTime.now(),
            deviceId: device.id,
            deviceName: device.name,
            totalKm: device.odometerKm,
            tripKm: device.tripKm,
            targetKm: device.attributes.trip?.target,
          );
          await notificationStore.add(notification);

          await notificationService.show(title: notification.title, body: notification.body, id: device.id, payload: notification.id);
        }

        final targetKm = device.attributes.trip?.target;
        final tripKm = device.tripKm;
        if (!config.tripAlert || targetKm == null || tripKm == null) continue;

        final remainingKm = targetKm - tripKm;
        final reached = remainingKm <= 0;

        // Sobe a cadência pra hora em hora quando algum veículo está perto
        // da meta — mesmo que ainda não tenha batido.
        if (remainingKm <= Constants.tripAlertHourlyThresholdKm) {
          hasNearTargetVehicle = true;
        }

        if (!reached) continue;

        // Continua marcado como "ativo" enquanto a meta permanecer batida —
        // só sai desse conjunto (voltando a poder notificar) quando o trip
        // for zerado/refeito e `reached` virar false num próximo ciclo.
        nextActiveTripAlerts.add(device.id);

        if (!activeTripAlerts.contains(device.id)) {
          final notification = AppNotificationModel(
            id: 'trip-${device.id}-${DateTime.now().millisecondsSinceEpoch}',
            type: 'trip',
            title: 'Meta de km atingida',
            body: 'Veículo ${device.name} atingiu ${tripKm.toStringAsFixed(2)} km.',
            createdAt: DateTime.now(),
            deviceId: device.id,
            deviceName: device.name,
            totalKm: device.odometerKm,
            tripKm: tripKm,
            targetKm: targetKm,
            remainingKm: remainingKm,
          );

          await notificationStore.add(notification);
          tripMessages.add(notification.body);
        }
      }

      await notificationStore.saveActiveTripAlerts(nextActiveTripAlerts);

      if (tripMessages.isNotEmpty) {
        await notificationService.show(title: 'Alerta de quilometragem', body: tripMessages.join('\n'), id: 1, payload: 'notifications');
      }

      await scheduleNextTripAlert(hasNearTargetVehicle: hasNearTargetVehicle);
    }

    return Future.value(true);
  });
}

Future<void> scheduleNextTripAlert({required bool hasNearTargetVehicle}) async {
  final minutes = hasNearTargetVehicle ? Constants.tripAlertHourlyFrequencyMinutes : Constants.tripAlertNormalFrequencyMinutes;

  await Workmanager().registerOneOffTask(
    Constants.taskTripAlertNext,
    Constants.taskTripAlert,
    initialDelay: Duration(minutes: minutes),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
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
