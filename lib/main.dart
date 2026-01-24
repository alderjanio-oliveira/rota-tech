// lib/main.dart
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/bindings/main.binding.dart';
import 'package:app_tracking/core/routes/routes.dart';
import 'package:app_tracking/ui/pages/home/home_page.dart';
import 'package:app_tracking/ui/pages/login/login_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  await GetStorage.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final TraccarService traccarService = TraccarService();

  MyApp({Key? key}) : super(key: key);

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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == true ? HomePage() : LoginPage();
        },
      ),
    );
  }

  Future<bool> _checkAuth() async {
    // Aqui você pode verificar se existe sessão salva
    return traccarService.jsessionId != null;
  }
}
