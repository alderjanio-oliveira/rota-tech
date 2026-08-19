import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/distance_reminder_model.dart';
import 'package:app_tracking/data/tracker_sms_command.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/models/daily_distance.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class VehicleDetailsController extends GetxController {
  final TraccarService traccarService;
  final DeviceModel device;
  final VehicleState vehicleState;

  VehicleDetailsController({required this.traccarService, required this.device, required this.vehicleState});

  final RxBool isLoading = false.obs;

  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  /// [device] é uma foto tirada na navegação; depois de recarregar
  /// `vehicleState` (que não reconstrói este controller), os dados dele
  /// ficam desatualizados. Use esse getter pra ler o estado atual.
  DeviceModel get liveDevice => vehicleState.list.firstWhereOrNull((d) => d.id == device.id) ?? device;

  final RxList<DailyDistance> dailyKmList = <DailyDistance>[].obs;
  final RxDouble dailyKm = 0.0.obs;
  final RxDouble totalKm = 0.0.obs;

  /// Cliente a quem este veículo está vinculado (busca por permissão no
  /// Traccar — não existe uma tabela local de vínculo, tudo é consultado ao
  /// vivo no servidor).
  final Rxn<ClientModel> linkedClient = Rxn<ClientModel>();
  final RxBool isLoadingClient = false.obs;

  /// "Trip A" — lembrete de quilometragem ativo (tabela própria no backend,
  /// não fica mais em attributes.trip do device).
  final Rxn<DistanceReminder> activeReminder = Rxn<DistanceReminder>();
  final RxBool isLoadingReminder = false.obs;
  final RxBool isSavingReminder = false.obs;

  /// Metas de km já concluídas/canceladas (mesma tabela do backend, só que
  /// filtrando o que não está mais pendente) — histórico de "zeradas".
  final RxList<DistanceReminder> reminderHistory = <DistanceReminder>[].obs;

  double? get _totalDistance => liveDevice.attributes.totalDistance;

  double? get reminderTraveledKm {
    final reminder = activeReminder.value;
    final total = _totalDistance;
    if (reminder == null || total == null) return null;
    return reminder.traveledFor(total) / 1000;
  }

  double? get reminderTargetKm {
    final reminder = activeReminder.value;
    if (reminder == null) return null;
    return reminder.thresholdDistance / 1000;
  }

  bool get reminderReached {
    final reminder = activeReminder.value;
    final total = _totalDistance;
    if (reminder == null || total == null) return false;
    return reminder.reachedFor(total);
  }

  final Rxn<String> reminderError = Rxn<String>();

  // ===============================
  // COMANDOS SMS (configuração do rastreador)
  // ===============================

  /// Só J16 por enquanto — [commandsFor] já está pronto pra outros modelos
  /// quando precisar.
  final List<SmsCommandTemplate> commands = commandsFor(TrackerModel.j16);

  /// Um TextEditingController por parâmetro de cada comando, já preenchido
  /// com o valor default — chave é "labelDoComando.chaveDoParametro".
  final Map<String, TextEditingController> paramControllers = {};

  /// Texto final de cada comando, num RxString — TextEditingController
  /// sozinho não notifica Obx, então cada campo dispara a atualização daqui
  /// no onChanged.
  final Map<String, RxString> previewByCommand = {};

  @override
  void onInit() {
    super.onInit();

    for (final command in commands) {
      for (final param in command.params) {
        paramControllers['${command.label}.${param.key}'] = TextEditingController(text: param.defaultValue);
      }
      previewByCommand[command.label] = buildCommand(command).obs;
    }

    // Sem busca automática de período: o usuário escolhe as datas e aperta o
    // filtro. Evita travar a entrada na tela com uma consulta pesada.
    _loadLinkedClient();
    _loadActiveReminder();
  }

  @override
  void onClose() {
    for (final controller in paramControllers.values) {
      controller.dispose();
    }
    super.onClose();
  }

  void refreshPreview(SmsCommandTemplate command) {
    previewByCommand[command.label]?.value = buildCommand(command);
  }

  String buildCommand(SmsCommandTemplate command) {
    final values = <String, String>{
      for (final param in command.params) param.key: paramControllers['${command.label}.${param.key}']?.text ?? param.defaultValue,
    };
    return command.build(values);
  }

  Future<void> sendBySms(SmsCommandTemplate command) async {
    final phone = liveDevice.phone ?? '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      Get.snackbar('Telefone não encontrado', 'Este dispositivo não tem número de chip cadastrado.');
      return;
    }

    final uri = Uri(scheme: 'sms', path: digits, queryParameters: {'body': buildCommand(command)});
    if (!await launchUrl(uri)) {
      Get.snackbar('Erro', 'Não foi possível abrir o app de mensagens.');
    }
  }

  void copyCommand(SmsCommandTemplate command) {
    Clipboard.setData(ClipboardData(text: buildCommand(command)));
    Get.snackbar('Copiado', 'Comando copiado pra área de transferência.');
  }

  Future<void> _loadLinkedClient() async {
    try {
      isLoadingClient.value = true;
      final users = await traccarService.getUsersByDevice(device.id);
      final owner = users.firstWhereOrNull((u) => u['administrator'] != true);
      if (owner == null) return;

      final attributes = owner['attributes'] ?? {};
      linkedClient.value = ClientModel.fromMap({
        'id': owner['id'],
        'name': owner['name'],
        'email': owner['email'],
        'phone': owner['phone'],
        'contractStart': attributes['contractStart'],
        'expiresAt': attributes['expiresAt'] ?? owner['expirationTime'],
        'notified': attributes['notified'] ?? false,
      });
    } catch (_) {
      // Usuário comum (não manager/admin) recebe 403 aqui — deixa em branco.
    } finally {
      isLoadingClient.value = false;
    }
  }

  Future<void> _loadActiveReminder() async {
    try {
      isLoadingReminder.value = true;
      final raw = await traccarService.getDistanceReminders(device.id);
      final reminders = raw.map(DistanceReminder.fromJson).toList();

      activeReminder.value = reminders.where((r) => r.isPending).firstOrNull;

      final history = reminders.where((r) => !r.isPending).toList()
        ..sort((a, b) => (b.confirmedAt ?? b.cancelledAt ?? DateTime(0)).compareTo(a.confirmedAt ?? a.cancelledAt ?? DateTime(0)));
      reminderHistory.value = history;
    } finally {
      isLoadingReminder.value = false;
    }
  }

  /// Cria a próxima "Trip A": se já houver um lembrete pendente, confirma o
  /// atual (o servidor fecha e calcula o km rodado final) antes de abrir um
  /// novo com a meta informada.
  Future<bool> saveReminder({required String name, required double targetKm}) async {
    reminderError.value = null;

    final total = _totalDistance;
    if (total == null) {
      reminderError.value = 'Odômetro do veículo ainda indisponível.';
      return false;
    }

    try {
      isSavingReminder.value = true;

      final current = activeReminder.value;
      if (current != null) {
        await traccarService.confirmDistanceReminder(current.id);
      }

      final created = await traccarService.createDistanceReminder(
        deviceId: device.id,
        name: name,
        thresholdDistance: targetKm * 1000,
        startValue: total,
      );

      if (created == null) return false;

      // Recarrega da fonte (não só seta o novo local) pra já trazer o
      // lembrete recém-confirmado pro histórico.
      await _loadActiveReminder();
      return true;
    } catch (e) {
      reminderError.value = e.toString();
      return false;
    } finally {
      isSavingReminder.value = false;
    }
  }

  Future<void> pickStartDate() async {
    startDate.value = await _pickDate();
  }

  Future<void> pickEndDate() async {
    endDate.value = await _pickDate();
  }

  Future<DateTime?> _pickDate() async {
    return await showDatePicker(context: Get.context!, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
  }

  Future<void> searchKmByPeriod() async {
    dailyKm.value = await traccarService.getDailyDistance(deviceId: device.id, day: DateTime.now()) ?? 0.0;
    if (startDate.value == null || endDate.value == null) return;

    isLoading.value = true;

    dailyKmList.value = await traccarService.getDistanceByDay(deviceId: device.id, from: startDate.value!, to: endDate.value!);
    totalKm.value = dailyKmList.fold(0.0, (sum, item) => sum + item.km);

    isLoading.value = false;
  }
}
