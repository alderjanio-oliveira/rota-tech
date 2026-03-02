// lib/main.dart
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/bindings/main.binding.dart';
import 'package:app_tracking/core/routes/routes.dart';
import 'package:app_tracking/core/services/notification_service.dart';
import 'package:app_tracking/core/services/work_manager_service.dart';
import 'package:app_tracking/ui/controllers/warnings/warning_controller.dart';
import 'package:app_tracking/ui/pages/home/home_page.dart';
import 'package:app_tracking/ui/pages/infos/trip_details_page.dart';
import 'package:app_tracking/ui/pages/login/login_page.dart';
import 'package:app_tracking/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  await GetStorage.init();
  Workmanager().initialize(callbackDispatcher);
  final notificationService = NotificationService();
  await notificationService.init();

  await Workmanager().registerPeriodicTask(
    Constants.taskTripAlert, // uniqueName
    Constants.taskTripAlert, // taskName
    frequency: Duration(minutes: 30),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  final launchDetails = await notificationService.getLaunchDetails();

  runApp(
    MyApp(
      notificationPayload: launchDetails?.notificationResponse?.payload,
    ),
  );
}

class MyApp extends StatelessWidget {
  final TraccarService traccarService = TraccarService();
  final String? notificationPayload;

  MyApp({super.key, this.notificationPayload});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Traccar App',
      initialBinding: MainBinding(),
      getPages: mainRouters,
      home: FutureBuilder<bool>(
        future: _checkAuth(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return choiseFirstPage(snapshot.data == true);
        },
      ),
    );
  }

  choiseFirstPage(data) {
    if (data == true) {
      if (Get.isRegistered<WarningController>()) return TripDetailsPage();
      return HomePage();
    } else {
      return LoginPage(
        notificationPayload: notificationPayload,
      );
    }
  }

  Future<bool> _checkAuth() async {
    // Aqui você pode verificar se existe sessão salva
    return traccarService.jsessionId != null;
  }
}
