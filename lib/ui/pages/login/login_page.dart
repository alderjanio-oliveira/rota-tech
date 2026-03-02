// lib/ui/pages/login/login_page.dart
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/ui/atoms/button/primary.dart';
import 'package:app_tracking/ui/atoms/inputs/text_input_field.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:app_tracking/ui/templates/base_page_template.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatelessWidget {
  final String? notificationPayload;
  final AuthController authController = Get.find();

  LoginPage({super.key, this.notificationPayload});

  @override
  Widget build(BuildContext context) {
    return BasePageTemplate(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 80),
            const SizedBox(height: 32),
            const Text('Traccar App', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Faça login para continuar', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            Obx(
              () => TextInputField(
                label: 'Email',
                controller: authController.emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: authController.errorMessage.value.isNotEmpty ? authController.errorMessage.value : null,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => TextInputField(
                label: 'Senha',
                controller: authController.passwordController,
                obscureText: authController.obscurePassword.value,
                suffixIcon: IconButton(
                  icon: Icon(authController.obscurePassword.value ? Icons.visibility_off : Icons.visibility),
                  onPressed: authController.togglePasswordVisibility,
                ),
              ),
            ),
            Obx(
              () => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Salvar login'),
                value: authController.rememberMe.value,
                onChanged: (value) {
                  authController.toggleRememberMe(value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Obx(() => PrimaryButton(text: 'Entrar', onPressed: _login, isLoading: authController.isLoading.value)),
          ],
        ),
      ),
    );
  }

  void _login() async {
    final success = await authController.login(authController.emailController.text.trim(), authController.passwordController.text);

    if (success) {
      if (notificationPayload != null) return Get.offAllNamed(Routes.TRIP_DETAILS, arguments: notificationPayload);
      Get.offAllNamed(Routes.HOME);
    }
  }
}
