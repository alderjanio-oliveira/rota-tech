// lib/main.dart
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/bindings/main.binding.dart';
import 'package:app_tracking/core/i18n/translation.dart';
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/routes/routes.dart';
import 'package:app_tracking/core/services/notification_service.dart';
import 'package:app_tracking/core/services/user_session_service.dart';
import 'package:app_tracking/core/services/work_manager_service.dart';
import 'package:app_tracking/ui/controllers/warnings/warning_controller.dart';
import 'package:app_tracking/ui/pages/home/home_page.dart';
import 'package:app_tracking/ui/pages/infos/trip_details_page.dart';
import 'package:app_tracking/ui/pages/login/login_page.dart';
import 'package:app_tracking/ui/theme/app_theme.dart';
import 'package:app_tracking/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await GetStorage.init();
  Workmanager().initialize(callbackDispatcher);
  final notificationService = NotificationService();
  await notificationService.init();

  await Workmanager().registerPeriodicTask(
    Constants.taskTripAlert, // uniqueName
    Constants.taskTripAlert, // taskName
    frequency: Duration(minutes: Constants.minFrequencyWorkmanager),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  Workmanager().registerOneOffTask(
    "trip_manual",
    Constants.taskTripAlert,
  );

  final launchDetails = await notificationService.getLaunchDetails();
  await notificationService.requestPermission();

  runApp(
    MyApp(
      notificationPayload: launchDetails?.notificationResponse?.payload,
    ),
  );
}

class MyApp extends StatelessWidget {
  // final TraccarService traccarService = TraccarService();
  final String? notificationPayload;

  const MyApp({super.key, this.notificationPayload});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // 🔥 automático
      translations: AppTranslations(),
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('en', 'US'),
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
      if (notificationPayload != null) return const NotificationsLaunchPage();
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
    if (Get.isRegistered<UserSessionService>()) {
      final sessionId = Get.find<UserSessionService>().sessionId;
      if (sessionId.isNotEmpty) {
        // Tente validar a sessão com o backend, se necessário
        return true;
      }
    }
    return false;
  }
}

class NotificationsLaunchPage extends StatelessWidget {
  const NotificationsLaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.NOTIFICATIONS);
    });

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
