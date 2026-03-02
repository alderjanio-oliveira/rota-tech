class BillingConfig {
  final String companyName;
  final String pixKey;
  final PixKeyType pixKeyType;
  final double price;

  BillingConfig({required this.companyName, required this.pixKey, required this.pixKeyType, required this.price});

  Map<String, dynamic> toJson() => {'companyName': companyName, 'pixKey': pixKey, 'pixKeyType': pixKeyType.name, 'price': price};

  factory BillingConfig.fromJson(Map<String, dynamic> json) {
    return BillingConfig(
      companyName: json['companyName'] ?? '',
      pixKey: json['pixKey'] ?? '',
      pixKeyType: PixKeyType.values.firstWhere((e) => e.name == json['pixKeyType'], orElse: () => PixKeyType.cpf),
      price: json['price']?.toDouble() ?? 0.0,
    );
  }
}

enum PixKeyType { cpf, cnpj, email, phone, random }
