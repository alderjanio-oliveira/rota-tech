class BillingConfig {
  final String companyName;
  final String pixKey;
  final PixKeyType pixKeyType;

  BillingConfig({required this.companyName, required this.pixKey, required this.pixKeyType});

  Map<String, dynamic> toJson() => {'companyName': companyName, 'pixKey': pixKey, 'pixKeyType': pixKeyType.name};

  factory BillingConfig.fromJson(Map<String, dynamic> json) {
    return BillingConfig(
      companyName: json['companyName'] ?? '',
      pixKey: json['pixKey'] ?? '',
      pixKeyType: PixKeyType.values.firstWhere((e) => e.name == json['pixKeyType'], orElse: () => PixKeyType.cpf),
    );
  }
}

enum PixKeyType { cpf, cnpj, email, phone, random }
