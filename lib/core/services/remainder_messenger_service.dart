import 'package:app_tracking/app/models/client_model.dart';
import 'package:app_tracking/core/services/local_billing_config_service.dart';
import 'package:app_tracking/ui/model/billing_config_model.dart';

class ReminderMessageService {
  final BillingConfigService billingConfigService = BillingConfigService();
  String buildMessage(ClientModel client, ReminderType type) {
    final start = client.expiresAt;
    final BillingConfig? config = billingConfigService.loadBillingConfig();

    switch (type) {
      case ReminderType.before:
        return '''
          Olá, Sr(a). ${client.name} 👋

          Este é um lembrete da mensalidade referente ao serviço da ${config?.companyName}.

          📅 Vencimento: ${start?.day}/${DateTime.now().month}/${DateTime.now().year}

          💳 PIX (${config?.pixKeyType}): ${config?.pixKey}

          Caso o pagamento já tenha sido realizado, por favor desconsidere.
          Agradecemos a confiança 🙏
       ''';

      case ReminderType.dueToday:
        return '''
          Sr(a) ${client.name}
          Hoje dia: ${start?.day} é o vencimento da sua mensalidade.

          💳 PIX (${config?.pixKeyType}): ${config?.pixKey}
          Ficamos no aguardo.
          Agradecemos a compreensão.
        ''';

      case ReminderType.overdue:
        return '''
          Sr(a) ${client.name}
          Sua mensalidade encontra-se em atraso.
          Pedimos que regularize o quanto antes.

          📅 Vencimento: no ultimo dia: ${start?.day}

          💳 PIX (${config?.pixKeyType}): ${config?.pixKey}

          caso o pagamento já tenha sido realizado, por favor desconsidere.
          Agradecemos a compreensão.
        ''';
    }
  }

  buildCongratulationMessage(ClientModel client) {
    final BillingConfig? config = billingConfigService.loadBillingConfig();
    return '''
      Olá, Sr(a). ${client.name} 👋

      Parabéns! 🎉 Seu contrato foi renovado com sucesso.

      Agradecemos a confiança depositada em nossos serviços.
      Estamos à disposição para qualquer necessidade.

      Atenciosamente,
      Equipe de ${config?.companyName}
    ''';
  }
}
