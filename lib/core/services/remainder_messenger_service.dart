import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:app_tracking/ui/model/billing_config_model.dart';

class ReminderMessageService {
  final BillingConfigService billingConfigService = BillingConfigService();

  String buildMessage(ClientModel client, ReminderType type) {
    final config = _loadValidBillingConfig();
    final pixType = pixKeyTypeLabel(config.pixKeyType);
    final dueDate = _formatDate(client.expiresAt);
    final promotionalPrice = _formatMoney(config.price);
    final overdueDays = client.daysToExpire < 0 ? client.daysToExpire.abs() : 0;
    final dailyInterest = _formatPercent(config.dailyInterestPercent);
    final overdueTotal = config.price + (config.price * (config.dailyInterestPercent / 100) * overdueDays);

    switch (type) {
      case ReminderType.before:
        return '''
      Olá, Sr(a). ${client.name} 👋

      Este é um lembrete da mensalidade referente ao serviço da ${config.companyName}.

      📅 Vencimento: $dueDate
      não deixe para última hora! 😉
      lembrando que o valor promocional é de R\$ $promotionalPrice
      APENAS ATÉ A DATA DE VENCIMENTO!

      💳 PIX ($pixType):
      ${config.pixKey}

      Caso o pagamento já tenha sido realizado, por favor desconsidere.
      Agradecemos a confiança 🙏
       ''';

      case ReminderType.dueToday:
        return '''
      Sr(a) ${client.name}
      Hoje, $dueDate, é o vencimento da sua mensalidade.

      💳 PIX ($pixType):
      ${config.pixKey}
      Valor promocional de R\$ $promotionalPrice válido somente até o final do dia de hoje!
      Ficamos no aguardo.
      Agradecemos a compreensão.
        ''';

      case ReminderType.overdue:
        return '''
      Sr(a) ${client.name}
      Sua mensalidade encontra-se em atraso.
      Pedimos que regularize o quanto antes.

      📅 Vencimento: $dueDate
      Dias em atraso: $overdueDays
      Após o vencimento, há acréscimo de $dailyInterest ao dia.
      Valor atualizado hoje: R\$ ${_formatMoney(overdueTotal)}

      💳 PIX ($pixType):
      ${config.pixKey}

      caso o pagamento já tenha sido realizado, por favor desconsidere.
      Agradecemos a compreensão.
        ''';
    }
  }

  String buildCongratulationMessage(ClientModel client) {
    final config = _loadValidBillingConfig();
    return '''
  Olá, Sr(a). ${client.name} 👋

  Parabéns! 🎉 Seu contrato foi renovado com sucesso.

  Agradecemos a confiança depositada em nossos serviços.
  Estamos à disposição para qualquer necessidade.

  Atenciosamente,
  Equipe de ${config.companyName}
    ''';
  }

  String buildClientInfoMessage(ClientModel client) {
    final config = _loadValidBillingConfig();
    final message = config.clientInfoMessage.trim().isNotEmpty ? config.clientInfoMessage.trim() : BillingConfig.defaultClientInfoMessage;

    return '''
$message

Condições financeiras:

- Valor acordado: R\$ ${_formatMoney(config.price)}.
- Valor válido até a data de vencimento: ${_formatDate(client.expiresAt)}.
- Após o vencimento, há acréscimo de ${_formatPercent(config.dailyInterestPercent)} ao dia.
    ''';
  }

  String buildContractOkMessage(ClientModel client) {
    return '''
Olá, Sr(a). ${client.name} 👋

Parabéns, seu contrato está em dias.

O próximo vencimento está previsto para ${_formatDate(client.expiresAt)}.

Agradecemos pela confiança e seguimos à disposição.
    ''';
  }

  BillingConfig _loadValidBillingConfig() {
    final config = billingConfigService.loadBillingConfig();

    if (config == null) {
      throw BillingConfigException('Configure os dados de cobrança antes de enviar mensagens.');
    }

    if (config.companyName.trim().isEmpty) {
      throw BillingConfigException('Informe o nome da empresa nas configurações de cobrança.');
    }

    if (config.pixKey.trim().isEmpty) {
      throw BillingConfigException('Informe a chave PIX nas configurações de cobrança.');
    }

    if (config.price <= 0) {
      throw BillingConfigException('Informe um valor de mensalidade maior que zero nas configurações de cobrança.');
    }

    if (config.dailyInterestPercent < 0) {
      throw BillingConfigException('Informe um juros diário válido nas configurações de cobrança.');
    }

    return config;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'sem vencimento';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');

    return '$day/$month/${local.year}';
  }

  String _formatMoney(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  String _formatPercent(double value) {
    final formatted = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

    return '${formatted.replaceAll('.', ',')}%';
  }

  String pixKeyTypeLabel(PixKeyType type) {
    switch (type) {
      case PixKeyType.cpf:
        return 'CPF';
      case PixKeyType.cnpj:
        return 'CNPJ';
      case PixKeyType.email:
        return 'E-mail';
      case PixKeyType.phone:
        return 'Telefone';
      case PixKeyType.random:
        return 'Chave Aleatória';
    }
  }
}

class BillingConfigException implements Exception {
  final String message;

  BillingConfigException(this.message);

  @override
  String toString() => message;
}
