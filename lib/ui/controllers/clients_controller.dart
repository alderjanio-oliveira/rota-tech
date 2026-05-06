// lib/features/clients/controller/clients_admin_controller.dart
import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/core/services/remainder_messenger_service.dart';
import 'package:app_tracking/data/client_state.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientsAdminController extends GetxController {
  final TraccarService traccarService;
  final messageServiceWhatsApp = ReminderMessageService();
  final ClientState clients = Get.find<ClientState>();
  final vehicleState = Get.find<VehicleState>();

  ClientsAdminController(this.traccarService);

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString search = ''.obs;
  final RxString filter = 'todos'.obs;

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  Future<void> loadClients() async {
    try {
      isLoading.value = true;
      error.value = '';
      final data = await traccarService.getClients();
      clients.list.assignAll(data.map((e) => ClientModel.fromMap(e)).toList()..sort((a, b) => a.daysToExpire.compareTo(b.daysToExpire)));
      loadDevicesPerUser();
    } catch (e) {
      error.value = 'Erro ao carregar clientes';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadDevicesPerUser() async {
    try {
      isLoading.value = true;
      error.value = '';
      final List<Map<String, dynamic>> data = await traccarService.getDevicesPerUser();

      final clientMap = {for (var c in clients.list) c.id: c};
      final deviceMap = {for (var d in vehicleState.list) d.id: d};
      for (var item in data) {
        final client = clientMap[item['userId']];
        final device = deviceMap[item['deviceId']];

        if (client != null && device != null) {
          client.devices ??= [];
          client.devices!.add(device);
        }
      }
      print(clients.list);

      // Processar os dados conforme necessário
    } catch (e) {
      error.value = 'Erro ao carregar dispositivos por usuário';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> renewContract(ClientModel client) async {
    if (client.expiresAt == null) return;

    final success = await traccarService.renewClientContract(client);

    if (success) {
      loadClients();
      try {
        final message = messageServiceWhatsApp.buildCongratulationMessage(client);
        await sendMessage(client, message);
      } on BillingConfigException catch (e) {
        _showBillingConfigError(e.message);
      }
    }
  }

  Future<void> sendWhatsAppReminder(ClientModel client) async {
    final days = client.daysToExpire;
    late String message;

    try {
      if (days > 0) {
        message = messageServiceWhatsApp.buildMessage(client, ReminderType.before);
      } else if (days == 0) {
        message = messageServiceWhatsApp.buildMessage(client, ReminderType.dueToday);
      } else {
        message = messageServiceWhatsApp.buildMessage(client, ReminderType.overdue);
      }
    } on BillingConfigException catch (e) {
      _showBillingConfigError(e.message);
      return;
    }

    await sendMessage(client, message);
  }

  Future<void> sendMessage(ClientModel client, String message) async {
    final phoneClient = client.phone;
    if (phoneClient == null || phoneClient.trim().isEmpty) {
      Get.snackbar('Telefone não encontrado', 'Informe o telefone do cliente antes de enviar a mensagem.');
      return;
    }

    final phone = phoneClient.replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty) {
      Get.snackbar('Telefone inválido', 'O telefone do cliente não possui números válidos.');
      return;
    }

    final encoded = Uri.encodeComponent(message);

    final uri = Uri.parse('https://wa.me/55$phone?text=$encoded');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Erro', 'Não foi possível abrir o WhatsApp');
    } else {
      // markClientAsNotified(client);
    }
  }

  void _showBillingConfigError(String message) {
    Get.defaultDialog(
      title: 'Configuração incompleta',
      middleText: '$message\n\nDeseja abrir as configurações de cobrança agora?',
      textCancel: 'Agora não',
      textConfirm: 'Configurar',
      onCancel: () => Get.back(),
      onConfirm: () {
        Get.back();
        Get.toNamed(Routes.BILLING_CONFIG);
      },
    );
  }
}
