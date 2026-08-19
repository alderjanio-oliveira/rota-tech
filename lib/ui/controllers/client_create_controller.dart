import 'package:app_tracking/app/services/client_admin_service.dart';
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/ui/controllers/clients_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ClientCreateController extends GetxController {
  final ClientAdminService clientAdminService;

  ClientCreateController({required this.clientAdminService});

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  final Rxn<DateTime> contractStart = Rxn<DateTime>();
  final Rxn<DateTime> expiresAt = Rxn<DateTime>();
  final RxBool isSaving = false.obs;

  /// Enquanto o usuário não escolher o vencimento manualmente, ele
  /// acompanha `contractStart + 1 mês` (mesma regra de qualquer renovação).
  bool _expiresAtTouchedManually = false;

  @override
  void onInit() {
    super.onInit();
    final today = DateTime.now();
    contractStart.value = DateTime(today.year, today.month, today.day);
    _recalculateExpiresAt();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void _recalculateExpiresAt() {
    final start = contractStart.value;
    if (start == null || _expiresAtTouchedManually) return;
    expiresAt.value = DateTime(start.year, start.month + 1, start.day);
  }

  Future<void> pickContractStart(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: contractStart.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      contractStart.value = DateTime(picked.year, picked.month, picked.day);
      _recalculateExpiresAt();
    }
  }

  Future<void> pickExpiresAt(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: expiresAt.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      _expiresAtTouchedManually = true;
      expiresAt.value = DateTime(picked.year, picked.month, picked.day);
    }
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Nome obrigatório', 'Informe o nome do cliente.');
      return;
    }
    if (emailController.text.trim().isEmpty) {
      Get.snackbar('E-mail obrigatório', 'Informe o e-mail do cliente.');
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      Get.snackbar('Senha obrigatória', 'Defina uma senha de acesso pro cliente.');
      return;
    }
    if (contractStart.value == null || expiresAt.value == null) {
      Get.snackbar('Datas obrigatórias', 'Informe o início do contrato e o primeiro vencimento.');
      return;
    }

    try {
      isSaving.value = true;

      final created = await clientAdminService.createClient(
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password: passwordController.text,
        contractStart: contractStart.value!,
        expiresAt: expiresAt.value!,
      );

      if (created == null) {
        Get.snackbar('Erro', 'Não foi possível cadastrar o cliente.');
        return;
      }

      _refreshClientsListIfOpen();
      Get.until((route) => route.settings.name == Routes.CLIENTS);
      Get.snackbar('Sucesso', 'Cliente cadastrado com sucesso.');
    } finally {
      isSaving.value = false;
    }
  }

  void _refreshClientsListIfOpen() {
    if (Get.isRegistered<ClientsAdminController>()) {
      Get.find<ClientsAdminController>().loadClients();
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Selecionar data';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
