import 'package:app_tracking/ui/controllers/billing_config_controller.dart';
import 'package:app_tracking/ui/model/billing_config_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BillingConfigPage extends GetView<BillingConfigController> {
  const BillingConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações de Cobrança')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nome da empresa'),
              onChanged: (v) => controller.companyName.value = v,
              controller: TextEditingController(text: controller.companyName.value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PixKeyType>(
              initialValue: controller.pixKeyType.value,
              items: PixKeyType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
              onChanged: (v) => controller.pixKeyType.value = v!,
              decoration: const InputDecoration(labelText: 'Tipo de chave PIX'),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Chave PIX'),
              onChanged: (v) => controller.pixKey.value = v,
              controller: TextEditingController(text: controller.pixKey.value),
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor'),
              onChanged: (v) => controller.price.value = double.tryParse(v) ?? 0.0,
              controller: TextEditingController(text: controller.price.value.toString()),
            ),

            const SizedBox(height: 24),
            ElevatedButton(onPressed: controller.save, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}
