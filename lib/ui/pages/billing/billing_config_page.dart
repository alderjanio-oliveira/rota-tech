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
      body: ListView(
        padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor'),
            onChanged: (v) => controller.price.value = double.tryParse(v) ?? 0.0,
            controller: TextEditingController(text: controller.price.value.toString()),
          ),
          const SizedBox(height: 12),
          TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Juros diário após vencimento (%)'),
            onChanged: (v) => controller.dailyInterestPercent.value = double.tryParse(v.replaceAll(',', '.')) ?? 1.5,
            controller: TextEditingController(text: controller.dailyInterestPercent.value.toString()),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mensagem de apresentação',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: controller.resetClientInfoMessage,
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller.clientInfoMessageController,
            minLines: 8,
            maxLines: 14,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              labelText: 'Texto enviado em "Enviar contrato"',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: controller.save, child: const Text('Salvar')),
        ],
      ),
    );
  }
}
