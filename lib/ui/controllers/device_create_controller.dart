import 'package:app_tracking/app/services/device_admin_service.dart';
import 'package:app_tracking/core/routes/app_routes.dart';
import 'package:app_tracking/data/vehicle_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DeviceCreateController extends GetxController {
  final DeviceAdminService deviceAdminService;
  final VehicleState vehicleState;

  DeviceCreateController({required this.deviceAdminService, required this.vehicleState});

  final nameController = TextEditingController();
  final imeiController = TextEditingController();
  final phoneController = TextEditingController();

  final RxBool isSaving = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    imeiController.dispose();
    phoneController.dispose();
    super.onClose();
  }

  Future<void> scanInto(TextEditingController target) async {
    final result = await Get.to<String>(() => const _BarcodeScanPage());
    if (result != null && result.isNotEmpty) {
      target.text = result;
    }
  }

  Future<void> save() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Nome obrigatório', 'Dê um nome pro dispositivo.');
      return;
    }
    if (imeiController.text.trim().isEmpty) {
      Get.snackbar('IMEI obrigatório', 'Informe ou escaneie o IMEI do rastreador.');
      return;
    }
    if (phoneController.text.trim().isEmpty) {
      Get.snackbar('Telefone obrigatório', 'Informe ou escaneie o número do chip.');
      return;
    }

    try {
      isSaving.value = true;
      final result = await deviceAdminService.createDevice(
        name: nameController.text,
        imei: imeiController.text,
        phone: phoneController.text,
      );

      if (!result.ok) {
        Get.snackbar('Erro', result.error ?? 'Não foi possível cadastrar o dispositivo.');
        return;
      }

      // Recarrega a lista pra pegar o device recém-criado (ainda não estava
      // no VehicleState) e já abre os detalhes dele, de onde dá pra mandar
      // os comandos de configuração por SMS.
      await vehicleState.loadDevices();
      final device = vehicleState.list.firstWhereOrNull((d) => d.id == result.id);

      if (device == null) {
        Get.snackbar('Dispositivo cadastrado', 'Encontre "${result.name}" na lista pra configurar por SMS.');
        Get.offNamed(Routes.HOME);
        return;
      }

      Get.offNamed(Routes.VEHICLE_DETAILS, arguments: device);
    } finally {
      isSaving.value = false;
    }
  }
}

/// Tela cheia de leitura de código de barras/QR — volta com o texto lido.
class _BarcodeScanPage extends StatefulWidget {
  const _BarcodeScanPage();

  @override
  State<_BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<_BarcodeScanPage> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    // A câmera continua analisando frames e dispararia onDetect de novo pro
    // mesmo código enquanto ele estiver no enquadramento — para a câmera já
    // na primeira leitura válida, antes de voltar, em vez de só ignorar
    // detecções repetidas (o que ainda deixava a leitura "correndo" por trás
    // da navegação de volta).
    if (_handled) return;

    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;

    _handled = true;
    _controller.stop();
    Get.back(result: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código')),
      body: MobileScanner(controller: _controller, onDetect: _onDetect),
    );
  }
}
