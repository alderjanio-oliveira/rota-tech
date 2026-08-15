import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/distance_reminder_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/models/daily_distance.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

  @override
  void onInit() {
    super.onInit();

    // Sem busca automática de período: o usuário escolhe as datas e aperta o
    // filtro. Evita travar a entrada na tela com uma consulta pesada.
    _loadLinkedClient();
    _loadActiveReminder();
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
      final pending = raw.map(DistanceReminder.fromJson).where((r) => r.isPending).toList();
      activeReminder.value = pending.firstOrNull;
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

      activeReminder.value = DistanceReminder.fromJson(created);
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
