import 'package:app_tracking/ui/controllers/device_create_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeviceCreatePage extends GetView<DeviceCreateController> {
  const DeviceCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar dispositivo')),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.directions_car_outlined)),
            ),
            const SizedBox(height: 12),
            _ScannableField(
              label: 'IMEI do rastreador',
              icon: Icons.memory,
              controller: controller.imeiController,
              onScan: () => controller.scanInto(controller.imeiController),
            ),
            const SizedBox(height: 12),
            _ScannableField(
              label: 'Número do chip',
              icon: Icons.sim_card_outlined,
              controller: controller.phoneController,
              onScan: () => controller.scanInto(controller.phoneController),
            ),
            const SizedBox(height: 8),
            const Text(
              'Depois de cadastrar você vai pra tela de detalhes do veículo, de onde dá pra enviar os comandos de configuração por SMS.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: controller.isSaving.value ? null : controller.save,
                icon: controller.isSaving.value
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_outlined),
                label: const Text('Cadastrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannableField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final VoidCallback onScan;

  const _ScannableField({required this.label, required this.icon, required this.controller, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: IconButton(tooltip: 'Escanear', icon: const Icon(Icons.qr_code_scanner), onPressed: onScan),
      ),
    );
  }
}
