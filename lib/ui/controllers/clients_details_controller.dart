import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/app/services/client_admin_service.dart';
import 'package:app_tracking/core/services/remainder_messenger_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientsDetailsController extends GetxController {
  final VehicleState vehicle;
  final ClientAdminService clientAdminService;
  final messageServiceWhatsApp = ReminderMessageService();

  ClientsDetailsController({
    required this.vehicle,
    required this.clientAdminService,
  });

  late ClientModel client;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final vehicleSearchController = TextEditingController();

  final Rxn<DateTime> expiresAt = Rxn<DateTime>();
  final RxString clientName = ''.obs;
  final RxSet<int> linkedDeviceIds = <int>{}.obs;
  final RxList<DeviceModel> linkedDevicesList = <DeviceModel>[].obs;
  final RxString vehicleSearch = ''.obs;
  final RxBool isSaving = false.obs;
  final RxBool isLoadingLinks = false.obs;
  final RxBool isLinking = false.obs;

  List<DeviceModel> get linkedDevices => linkedDevicesList.toList();

  List<DeviceModel> get availableDevices {
    final search = vehicleSearch.value.trim().toLowerCase();
    if (search.isEmpty) return <DeviceModel>[];

    return vehicle.list.where((device) {
      final isLinked = linkedDeviceIds.contains(device.id);
      final matchSearch = device.name.toLowerCase().contains(search) || device.id.toString().contains(search);

      return !isLinked && matchSearch;
    }).toList();
  }

  int get daysToExpire {
    final expiration = expiresAt.value;
    if (expiration == null) return 9999;

    final expirationDate = DateTime(expiration.year, expiration.month, expiration.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return expirationDate.difference(today).inDays;
  }

  @override
  void onInit() {
    super.onInit();
    client = Get.arguments as ClientModel;
    clientName.value = client.name;
    nameController.text = client.name;
    emailController.text = client.email ?? '';
    phoneController.text = client.phone ?? '';
    expiresAt.value = client.expiresAt;
    final initialDevices = client.devices ?? <DeviceModel>[];
    linkedDevicesList.assignAll(initialDevices);
    linkedDeviceIds.assignAll(initialDevices.map((device) => device.id));
    _ensureVehiclesLoaded();
    loadLinkedDevices();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    vehicleSearchController.dispose();
    super.onClose();
  }

  Future<void> pickExpirationDate(BuildContext context) async {
    final now = DateTime.now();
    final currentDate = expiresAt.value ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      expiresAt.value = DateTime(picked.year, picked.month, picked.day);
    }
  }

  Future<void> loadLinkedDevices() async {
    try {
      isLoadingLinks.value = true;
      final devices = await clientAdminService.getLinkedDevices(client.id);
      linkedDevicesList.assignAll(devices);
      linkedDeviceIds.assignAll(devices.map((device) => device.id));
    } finally {
      isLoadingLinks.value = false;
    }
  }

  Future<void> _ensureVehiclesLoaded() async {
    if (vehicle.list.isEmpty) {
      await vehicle.load();
    }
  }

  Future<void> saveClient() async {
    final expiration = expiresAt.value;
    if (expiration == null) {
      Get.snackbar('Vencimento obrigatório', 'Informe a data de expiração do cliente.');
      return;
    }

    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Nome obrigatório', 'Informe o nome do cliente.');
      return;
    }

    if (emailController.text.trim().isEmpty) {
      Get.snackbar('E-mail obrigatório', 'Informe o e-mail do cliente.');
      return;
    }

    try {
      isSaving.value = true;
      final updated = await clientAdminService.updateClient(
        client: client,
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        expiresAt: expiration,
        password: passwordController.text,
      );

      if (updated == null) {
        Get.snackbar('Erro', 'Não foi possível atualizar o cliente.');
        return;
      }

      client = updated.copyWith(devices: linkedDevices);
      clientName.value = updated.name;
      passwordController.clear();
      Get.snackbar('Sucesso', 'Cliente atualizado com sucesso.');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> sendClientInfoMessage() async {
    final message = messageServiceWhatsApp.buildClientInfoMessage(client);
    await _sendWhatsAppMessage(message);
  }

  Future<void> sendBillingMessage() async {
    try {
      final days = daysToExpire;
      final type = days > 0 ? ReminderType.before : (days == 0 ? ReminderType.dueToday : ReminderType.overdue);
      final message = messageServiceWhatsApp.buildMessage(client.copyWith(expiresAt: expiresAt.value), type);
      await _sendWhatsAppMessage(message);
    } on BillingConfigException catch (e) {
      Get.snackbar('Configuração incompleta', e.message);
    }
  }

  Future<void> sendContractOkMessage() async {
    final message = messageServiceWhatsApp.buildContractOkMessage(client.copyWith(expiresAt: expiresAt.value));
    await _sendWhatsAppMessage(message);
  }

  Future<void> _sendWhatsAppMessage(String message) async {
    final phoneClient = phoneController.text.trim().isNotEmpty ? phoneController.text : client.phone;
    if (phoneClient == null || phoneClient.trim().isEmpty) {
      Get.snackbar('Telefone não encontrado', 'Informe o telefone do cliente antes de enviar a mensagem.');
      return;
    }

    final phone = phoneClient.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      Get.snackbar('Telefone inválido', 'O telefone do cliente não possui números válidos.');
      return;
    }

    final uri = Uri.parse('https://wa.me/55$phone?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Erro', 'Não foi possível abrir o WhatsApp');
    }
  }

  void confirmLink(DeviceModel device) {
    Get.defaultDialog(
      title: 'Vincular veículo',
      middleText: 'Deseja vincular ${device.name} ao cliente ${client.name}?',
      textCancel: 'Cancelar',
      textConfirm: 'Vincular',
      onCancel: () => Get.back(),
      onConfirm: () {
        Get.back();
        link(device);
      },
    );
  }

  Future<void> link(DeviceModel device) async {
    try {
      isLinking.value = true;
      final success = await clientAdminService.linkDevice(userId: client.id, deviceId: device.id);

      if (success) {
        linkedDeviceIds.add(device.id);
        linkedDevicesList.add(device);
        vehicleSearchController.clear();
        vehicleSearch.value = '';
        Get.snackbar('Sucesso', 'Veículo vinculado ao cliente.');
      } else {
        Get.snackbar('Erro', 'Falha ao vincular veículo.');
      }
    } finally {
      isLinking.value = false;
    }
  }

  void confirmUnlink(DeviceModel device) {
    Get.defaultDialog(
      title: 'Remover vínculo',
      middleText: 'Deseja remover ${device.name} deste cliente?',
      textCancel: 'Cancelar',
      textConfirm: 'Remover',
      onCancel: () => Get.back(),
      onConfirm: () {
        Get.back();
        unlink(device);
      },
    );
  }

  Future<void> unlink(DeviceModel device) async {
    try {
      isLinking.value = true;
      final success = await clientAdminService.unlinkDevice(userId: client.id, deviceId: device.id);

      if (success) {
        linkedDeviceIds.remove(device.id);
        linkedDevicesList.removeWhere((item) => item.id == device.id);
        Get.snackbar('Sucesso', 'Vínculo removido.');
      } else {
        Get.snackbar('Erro', 'Falha ao remover vínculo.');
      }
    } finally {
      isLinking.value = false;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Selecionar data';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}
