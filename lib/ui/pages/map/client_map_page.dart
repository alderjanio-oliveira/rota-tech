import 'package:app_tracking/ui/pages/map/map_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tela de mapa acessada via [Routes.MAP] — hoje usada para "ver no mapa"
/// os veículos de um cliente específico (vindo da tela de detalhes do
/// cliente, modo admin). Espera `Get.arguments` como
/// `{'deviceIds': List<int>, 'label': String}` (ambos opcionais).
class ClientMapPage extends StatelessWidget {
  const ClientMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    final deviceIds = args is Map ? (args['deviceIds'] as List?)?.cast<int>() : null;
    final label = args is Map ? args['label'] as String? : null;

    return Scaffold(
      appBar: AppBar(title: Text(label != null ? 'Mapa — $label' : 'Mapa')),
      body: MapWidget(deviceIds: deviceIds, filterLabel: label),
    );
  }
}
