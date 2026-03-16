// lib/ui/controllers/auth_controller.dart
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/services/auth_service.dart';
import 'package:app_tracking/core/services/auth_storage_service.dart';
import 'package:app_tracking/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:workmanager/workmanager.dart';

class AuthController extends GetxController {
  final TraccarService traccarService;
  final AuthService authService;

  AuthController({
    required this.traccarService,
    required this.authService,
  });

  final AuthStorageService authStorageService = AuthStorageService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = RxString('');
  final RxBool isLoggedIn = false.obs;

  final obscurePassword = true.obs;
  final rememberMe = false.obs;

  @override
  void onInit() {
    super.onInit();
    Workmanager().registerOneOffTask(
      Constants.taskTripAlert,
      Constants.taskTripAlert,
      initialDelay: Duration(seconds: 20), // Aguarda 10 segundos para garantir que o app esteja totalmente inicializado
    );
    _loadRememberedCredentials();
  }

  void _loadRememberedCredentials() async {
    emailController.text = await authStorageService.getEmail() ?? '';
    passwordController.text = await authStorageService.getPassword() ?? '';
    rememberMe.value = await authStorageService.rememberMe();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void toggleRememberMe(bool value) {
    rememberMe.value = value;
  }

  Future<bool> login(String email, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final success = await authService.login(email, password);

      if (success) {
        isLoggedIn.value = true;
        if (rememberMe.value) await authStorageService.saveCredentials(email: email, password: password);
        return true;
      } else {
        errorMessage.value = 'Credenciais inválidas';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Erro ao fazer login: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
    authService.logout();
    isLoggedIn.value = false;
  }
}
