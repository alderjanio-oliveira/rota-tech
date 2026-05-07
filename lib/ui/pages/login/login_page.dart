// lib/ui/pages/login/login_page.dart
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/ui/atoms/button/primary.dart';
import 'package:app_tracking/ui/atoms/inputs/text_input_field.dart';
import 'package:app_tracking/ui/controllers/auth_controller.dart';
import 'package:app_tracking/ui/templates/base_page_template.dart';
import 'package:app_tracking/ui/theme/app_spacing.dart';
import 'package:app_tracking/ui/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatelessWidget {
  final String? notificationPayload;
  final AuthController authController = Get.find();

  LoginPage({super.key, this.notificationPayload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BasePageTemplate(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// LOGO + BRAND
              // Center(
              //   child: Column(
              //     children: [
              //       Image.asset(
              //         'assets/logo.png',
              //         height: 80,
              //       ),
              //       const SizedBox(height: AppSpacing.md),
              //       Text(
              //         'RotaTec',
              //         style: AppTextStyles.title.copyWith(fontSize: 24),
              //       ),
              //     ],
              //   ),
              // ),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'RT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              /// TITLE
              Center(
                child: Text(
                  'login_title'.tr,
                  style: AppTextStyles.title.copyWith(fontSize: 20),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              /// SUBTITLE
              Center(
                child: Text(
                  'login_subtitle'.tr,
                  style: AppTextStyles.body.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              /// EMAIL
              TextInputField(
                label: 'email'.tr,
                controller: authController.emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: AppSpacing.lg),

              /// PASSWORD
              Obx(
                () => TextInputField(
                  label: 'password'.tr,
                  controller: authController.passwordController,
                  obscureText: authController.obscurePassword.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      authController.obscurePassword.value ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: authController.togglePasswordVisibility,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              /// REMEMBER ME
              Obx(
                () => Row(
                  children: [
                    Checkbox(
                      value: authController.rememberMe.value,
                      onChanged: (value) => authController.toggleRememberMe(value ?? false),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'remember_me'.tr,
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              /// BUTTON
              Obx(
                () => PrimaryButton(
                  text: 'login'.tr,
                  onPressed: _login,
                  isLoading: authController.isLoading.value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    final success = await authController.login(
      authController.emailController.text.trim(),
      authController.passwordController.text,
    );

    if (success) {
      if (notificationPayload != null) {
        return Get.offAllNamed(
          Routes.NOTIFICATIONS,
        );
      }
      Get.offAllNamed(Routes.HOME);
    }
  }
}
