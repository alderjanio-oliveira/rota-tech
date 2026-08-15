import 'package:app_tracking/app/services/traccar_service.dart';
import 'package:app_tracking/core/ui/drawer/scaffold/app_scaffold.dart';
import 'package:app_tracking/data/device_model.dart';
import 'package:app_tracking/data/distance_reminder_model.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:app_tracking/ui/pages/infos/molecule/trip_item_molecule.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lista os veículos com um lembrete de quilometragem ativo — busca
/// /api/distancereminders por device (não existe uma listagem em lote com o
/// device já identificado, então é uma chamada por veículo).
class TripDetailsPage extends StatefulWidget {
  const TripDetailsPage({super.key});

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  final _vehicleState = Get.find<VehicleState>();
  final _traccarService = Get.find<TraccarService>();

  bool _isLoading = true;
  final List<DeviceReminder> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final results = <DeviceReminder>[];
    for (final device in _vehicleState.list) {
      final totalDistance = device.attributes.totalDistance;
      if (totalDistance == null) continue;

      final raw = await _traccarService.getDistanceReminders(device.id);
      final pending = raw.map(DistanceReminder.fromJson).where((r) => r.isPending).toList();
      if (pending.isEmpty) continue;

      results.add(DeviceReminder(device: device, reminder: pending.first, totalDistance: totalDistance));
    }

    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(results);
      _isLoading = false;
    });
  }

  Future<void> _cancel(DeviceReminder item) async {
    final success = await _traccarService.cancelDistanceReminder(item.reminder.id);
    if (!success) {
      Get.snackbar('Erro', 'Não foi possível cancelar o lembrete.');
      return;
    }
    setState(() => _items.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Kms rodados')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum lembrete de quilometragem ativo no momento.')))
              : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return TripItemMolecule(item: item, onCancel: () => _cancel(item));
                  },
                ),
              ),
    );
  }
}

class DeviceReminder {
  final DeviceModel device;
  final DistanceReminder reminder;
  final double totalDistance;

  const DeviceReminder({required this.device, required this.reminder, required this.totalDistance});
}
