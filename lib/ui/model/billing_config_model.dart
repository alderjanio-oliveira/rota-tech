class BillingConfig {
  final String companyName;
  final String pixKey;
  final PixKeyType pixKeyType;
  final double price;
  final double dailyInterestPercent;
  final String clientInfoMessage;

  BillingConfig({
    required this.companyName,
    required this.pixKey,
    required this.pixKeyType,
    required this.price,
    this.dailyInterestPercent = 1.5,
    String? clientInfoMessage,
  }) : clientInfoMessage = clientInfoMessage ?? defaultClientInfoMessage;

  static const defaultClientInfoMessage = '''
Prezado cliente, tudo bem?

Parabéns por usar nossos serviços.

Segue um resumo simples do que você conta conosco:

- Rastreamento 24h do seu veículo.
- Notificações inteligentes para ajudar no acompanhamento.
- Controle de quilometragem para facilitar sua rotina.
- Atendimento sem contrato de fidelidade.
- O valor acordado da mensalidade é válido até a data de vencimento.
- Após o vencimento, há acréscimo de juros diários conforme informado no atendimento.

Também prezamos pela transparência:

- Você pode cancelar a qualquer momento, sem ônus.
- Em caso de atraso por 10 dias corridos, o sistema poderá entrar em modo de bloqueio automático.
- Em caso de cancelamento, pedimos que agende a retirada do rastreador antes desse prazo para evitar transtornos.

Seguimos à disposição.
''';

  Map<String, dynamic> toJson() => {
        'companyName': companyName,
        'pixKey': pixKey,
        'pixKeyType': pixKeyType.name,
        'price': price,
        'dailyInterestPercent': dailyInterestPercent,
        'clientInfoMessage': clientInfoMessage,
      };

  factory BillingConfig.fromJson(Map<String, dynamic> json) {
    return BillingConfig(
      companyName: json['companyName'] ?? '',
      pixKey: json['pixKey'] ?? '',
      pixKeyType: PixKeyType.values.firstWhere((e) => e.name == json['pixKeyType'], orElse: () => PixKeyType.cpf),
      price: json['price']?.toDouble() ?? 0.0,
      dailyInterestPercent: json['dailyInterestPercent']?.toDouble() ?? 1.5,
      clientInfoMessage: json['clientInfoMessage'] ?? defaultClientInfoMessage,
    );
  }
}

enum PixKeyType { cpf, cnpj, email, phone, random }
