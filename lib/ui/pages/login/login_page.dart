// lib/ui/pages/login/login_page.dart
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/services/notification_service.dart';
import 'package:app_tracking/ui/atoms/button/primary.dart';
import 'package:app_tracking/ui/atoms/inputs/text_input_field.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:app_tracking/ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class LoginPage extends StatelessWidget {
  final String? notificationPayload;
  final AuthController authController = Get.find();

  LoginPage({super.key, this.notificationPayload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _LoginHero(),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('login_title'.tr, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('login_subtitle'.tr, style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color)),

                    const SizedBox(height: 24),

                    Obx(
                      () =>
                          authController.errorMessage.value.isEmpty
                              ? const SizedBox.shrink()
                              : Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _ErrorBanner(message: authController.errorMessage.value),
                              ),
                    ),

                    /// EMAIL
                    TextInputField(label: 'email'.tr, controller: authController.emailController, keyboardType: TextInputType.emailAddress),

                    const SizedBox(height: 16),

                    /// PASSWORD
                    Obx(
                      () => TextInputField(
                        label: 'password'.tr,
                        controller: authController.passwordController,
                        obscureText: authController.obscurePassword.value,
                        suffixIcon: IconButton(
                          icon: Icon(authController.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: authController.togglePasswordVisibility,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// REMEMBER ME
                    Obx(
                      () => Row(
                        children: [
                          Checkbox(
                            value: authController.rememberMe.value,
                            onChanged: (value) => authController.toggleRememberMe(value ?? false),
                          ),
                          Text('remember_me'.tr, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    /// BUTTON
                    Obx(() => PrimaryButton(text: 'login'.tr, onPressed: _login, isLoading: authController.isLoading.value)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    final success = await authController.login(authController.emailController.text.trim(), authController.passwordController.text);

    if (success) {
      final pendingRoute = NotificationService.consumePendingNavigation();
      if (notificationPayload != null || pendingRoute != null) {
        return Get.offAllNamed(Routes.NOTIFICATIONS);
      }
      Get.offAllNamed(Routes.HOME);
    }
  }
}

/// Cabeçalho com o mesmo gradiente de marca da splash, cantos arredondados
/// na base "encaixando" no card do formulário.
class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topInset + 40, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dark, Color(0xFF17517D), AppColors.primary],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 14),
          const Text('RotaTec', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Rastreamento inteligente de frotas', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}
